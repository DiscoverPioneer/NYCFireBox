import UIKit
import MapKit
import OneSignal

class SearchViewController: UIViewController {
    private var fireBoxes: [FireBox] = []
    private var filteredBoxes: [FireBox] = []
    private var locations: [Location] = []
    private var searchController = UISearchController(searchResultsController: nil)

    @IBOutlet var tableView: UITableView!
    private var mapView: Map?
    private var noResultsLabel = UILabel()
    private var mapNavButton: UIBarButtonItem?

    private let infoProvider = InfoActionsProvider()
    private let constants = Constants()
    private var queryFormatter: SearchQueryFormatter?

    override func viewDidLoad() {
        super.viewDidLoad()
        queryFormatter = SearchQueryFormatter(appLocation: constants.appLocation)
        setupViews()
        getLocations()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        GoogleAnalyticsController.shared.trackScreen(name: "SearchViewController")
    }

    override func resignFirstResponder() -> Bool {
        return searchController.searchBar.resignFirstResponder()
    }

    private func setupViews() {
        self.view.backgroundColor = .white
        setupNavigationBar()
        setupMapView()
        setupTableView()
        setupNoResults()
    }

    private func setupNoResults() {
        noResultsLabel.text = "No Results"
        noResultsLabel.textColor = .gray
        noResultsLabel.textAlignment = .center
        noResultsLabel.frame = CGRect(origin: CGPoint(x: 0,y :0),
                                      size: CGSize(width: self.view.bounds.size.width,
                                                   height: self.view.bounds.size.height))
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        tableView.backgroundView = mapView
    }

    private func setupMapView() {
        mapView = Map(frame: CGRect(origin: CGPoint(x: 0,y :0),
                                       size: CGSize(width: view.bounds.size.width,
                                                    height: view.bounds.size.height)))
        let startCoordinates = DataProvider.getDefaultCoordinates()
        mapView?.setupMapRegion(startCoordinates: startCoordinates, radius: 3000)
    }

    private func getLocations() {
        DataProvider.getFireBoxes { [weak self] (fireBoxes) in
            self?.fireBoxes = fireBoxes
        }
        
        DataProvider.getEMSStations { [weak self] (emsStations) in
            for station in emsStations {
                self?.locations.append(station)
            }
            self?.updateMap(withLocations: emsStations)
        }

        DataProvider.getFirehouses { [weak self] (firehouses) in
            self?.locations.append(contentsOf: firehouses)
            self?.updateMap(withLocations: firehouses)
        }

        showNoResult(true)
    }

    private func setupNavigationBar() {
        title = constants.title
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Enter box number"
        searchController.searchBar.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.keyboardType = .numberPad
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController = searchController

       
        let infoButton = UIBarButtonItem(image: UIImage(named:"Info"), style: .plain, target: self, action: #selector(onInfoButton(_:)))
        mapNavButton = UIBarButtonItem(title: "Map",
                                        style: .plain,
                                        target: self,
                                        action: #selector(onMapButton(_:)))
        self.navigationItem.leftBarButtonItems = [infoButton]
        self.navigationItem.rightBarButtonItem = mapNavButton
    }

    private func showNoResult(_ shouldShow: Bool) {
        let shouldShowMap = searchController.searchBar.text?.isEmpty ?? true
            || searchController.searchBar.text ?? "" == queryFormatter?.startQuery
        tableView.backgroundView = shouldShowMap ? mapView : noResultsLabel
        tableView.backgroundView?.isHidden = !shouldShow

        navigationItem.rightBarButtonItem = shouldShowMap ? nil : mapNavButton
    }

    private func clearSearch() {
        filteredBoxes.removeAll()
        tableView.reloadData()
        showNoResult(filteredBoxes.isEmpty)
    }

    private func filter(searchQuery: String? ) {
        guard let searchText = searchQuery,
            let validQuery = queryFormatter?.isValid(query: searchText),
            validQuery else { return }

        let filteredBoxes = fireBoxes.filter { (box) -> Bool in
            if box.boxNumber == searchQuery && box.address.contains("LGA") {
                print("here: \(box.address),\(box.longitude)")
            }
            return box.boxNumber == searchQuery
        }

        self.filteredBoxes = filteredBoxes
        showNoResult(filteredBoxes.isEmpty)
        tableView.reloadData()
    }

    private func updateMap(withLocations locations: [Location]) {
        for location in locations {
            mapView?.addMarker(toLocation: location, color: .red)
        }
    }

    // MARK: Actions
    @objc private func onInfoButton(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let actions = infoProvider.getAlertActions()

        for action in actions {
            actionSheet.addAction(action)
            print("action \(action)")
        }

        _ = resignFirstResponder()
        searchController.isActive = false
        setActionSheet(actionSheet: actionSheet)

        present(actionSheet, animated: true, completion: nil)
    }

    func setActionSheet(actionSheet: UIAlertController) {
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
    }

    @objc private func onMapButton(_ sender: UIBarButtonItem) {
        searchController.searchBar.text?.removeAll()
        searchController.isActive = false
        clearSearch()
    }
}

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filter(searchQuery: searchController.searchBar.text)
    }
}

extension SearchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return filteredBoxes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FireBoxCell.cellID, for: indexPath) as! FireBoxCell
        cell.populate(withBox: filteredBoxes[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return FireBoxCell.defaultHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        _ = resignFirstResponder()
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)

        if let detailsVC = storyboard.instantiateViewController(withIdentifier: "FireBoxDetailsController") as? FireBoxDetailsController {
            navigationController?.pushViewController(detailsVC, animated: true)
            detailsVC.update(withBox: filteredBoxes[indexPath.row], locations: locations)
            GoogleAnalyticsController().trackEvent(category: "FireBoxLocation", action: "selected", label: filteredBoxes[indexPath.row].boxNumber, value: 1)
        }
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        searchBar.text = queryFormatter?.getSearchQuery(text: searchBar.text ?? "", newText: text, range: range)
        return false
    }

     func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.text = queryFormatter?.startQuery
        return true
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchBar.text ?? "").isEmpty {
            searchBar.text = queryFormatter?.startQuery
        }
    }
}
