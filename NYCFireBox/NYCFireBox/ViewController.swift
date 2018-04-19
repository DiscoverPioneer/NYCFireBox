import UIKit
import MapKit

class ViewController: UIViewController {
    private var fireBoxes: [FireBox] = []
    private var filteredBoxes: [FireBox] = []
    private var firehouses: [Firehouse] = []
    private var emsStations: [EMSStation] = []
    private var searchController = UISearchController(searchResultsController: nil)
    @IBOutlet var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupViews()
        getLocations()
    }

    private func setupViews() {
        self.view.backgroundColor = .white
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Enter box number"
        searchController.searchBar.delegate = self
        searchController.searchBar.keyboardType = .numberPad
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController = searchController

        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .none
    }

    private func getLocations() {
        DataProvider.getFireBoxes { [weak self] (fireBoxes) in
            self?.fireBoxes = fireBoxes
        }

        DataProvider.getEMSStations { [weak self] (emsStations) in
            self?.emsStations = emsStations
        }

        let boroughs: [NYCBoroughs] = [.statenIsland, .queens, .manhattan, .brooklyn, .bronx]
        for borough in boroughs {
            DataProvider.getFirehouses(forBorough: borough, completionHandler: { [weak self] (firehouses) in
                self?.firehouses.append(contentsOf: firehouses)
            })
        }
    }

    private func setupNavigationBar() {
        let infoButton = UIBarButtonItem(title: "Info",
                                         style: .plain,
                                         target: self,
                                         action: #selector(onInfoButton(_:)))
        self.navigationItem.leftBarButtonItem = infoButton
    }

    private func showNoResult(_ shouldShow: Bool) {
        if shouldShow {
            let rect = CGRect(origin: CGPoint(x: 0,y :0),
                              size: CGSize(width: self.view.bounds.size.width, height: self.view.bounds.size.height))
            let messageLabel = UILabel(frame: rect)
            messageLabel.text = "No results"
            messageLabel.textColor = .gray
            messageLabel.textAlignment = .center
            messageLabel.adjustsFontSizeToFitWidth = true
            tableView.backgroundView = messageLabel;
        } else {
            tableView.backgroundView = nil
        }
    }

    private func clearSearch() {
        filteredBoxes.removeAll()
        tableView.reloadData()
    }

    private func filter(searchQuery: String? ) {
        guard let searchText = searchQuery, searchText.count == maxQueryLength() else {
            clearSearch()
            return
        }

        let filteredBoxes = fireBoxes.filter { (box) -> Bool in
            return box.boxNumber == searchQuery
        }

        self.filteredBoxes = filteredBoxes
        tableView.reloadData()
    }

    private func maxQueryLength() -> Int {
        return 4
    }

    private func openMaps(forBox box: FireBox) {
        let locationCoordinates = box.coordinates.toCoordinates()
        let regionDistance: CLLocationDistance = 500
        let coordinates = CLLocationCoordinate2DMake(locationCoordinates.latitude, locationCoordinates.longitude)
        let regionSpan = MKCoordinateRegionMakeWithDistance(coordinates, regionDistance, regionDistance)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]

        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = box.address

        MKMapItem.openMaps(with: [mapItem], launchOptions: options)
    }

    // MARK: Actions
    @objc private func onInfoButton(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let contact = UIAlertAction(title: "Contact Us", style: .default) { [weak self] (action) in
            self?.open(email: NetworkConstants.InfoURL.contact)
        }

        let website = UIAlertAction(title: "Website", style: .default) { [weak self] (action) in
            self?.open(url: NetworkConstants.InfoURL.website)
        }

        let liveIncidents = UIAlertAction(title: "Live Incidents", style: .default) { [weak self] (action) in
            self?.open(url: NetworkConstants.InfoURL.liveIncidents)
        }

        let mobile = UIAlertAction(title: "Mobile MDT", style: .default) { [weak self] (action) in
            self?.open(url: NetworkConstants.InfoURL.mobileMDT)
        }

        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        actionSheet.addAction(contact)
        actionSheet.addAction(website)
        actionSheet.addAction(liveIncidents)
        actionSheet.addAction(mobile)
        actionSheet.addAction(cancel)
        present(actionSheet, animated: true, completion: nil)
    }

    private func open(url: String) {
        guard let url = URL(string: url) else { return }
        UIApplication.shared.open(url)
    }

    private func open(email: String) {
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
}

extension ViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filter(searchQuery: searchController.searchBar.text)
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        showNoResult(filteredBoxes.isEmpty)
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
        openMaps(forBox: filteredBoxes[indexPath.row])
    }
}

extension ViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let totalCharacters = (searchBar.text?.appending(text).count ?? 0) - range.length
        return totalCharacters <= maxQueryLength()
    }
}

