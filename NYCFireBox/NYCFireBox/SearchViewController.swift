import UIKit
import MapKit
#if canImport(OneSignalFramework)
import OneSignalFramework
#endif

class SearchViewController: UIViewController {
    private var fireBoxes: [FireBox] = []
    private var filteredBoxes: [FireBox] = []
    private var locations: [Location] = []
    private var loadedLocationKeys = Set<String>()
    private var searchController = UISearchController(searchResultsController: nil)

    @IBOutlet var tableView: UITableView!
    private var mapView: Map?
    private var noResultsLabel = UILabel()
    private var loadingLabel = UILabel()
    private var mapNavButton: UIBarButtonItem?
    private var searchNavButton: UIBarButtonItem?

    private var kStartQuery = "0000"

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        getLocations()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        GoogleAnalyticsController.shared.trackScreen(name: "SearchViewController")
        mapView?.mapView.hideAllGadgets = true
    }

    override func resignFirstResponder() -> Bool {
        return searchController.searchBar.resignFirstResponder()
    }

    private func setupViews() {
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        setupNavigationBar()
        setupMapView()
        setupTableView()
        setupNoResults()
        setupLoadingView()
    }

    private func setupNoResults() {
        noResultsLabel.text = "No matching fire boxes"
        noResultsLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        noResultsLabel.textColor = .gray
        noResultsLabel.textAlignment = .center
        noResultsLabel.frame = CGRect(origin: CGPoint(x: 0,y :0),
                                      size: CGSize(width: self.view.bounds.size.width,
                                                   height: self.view.bounds.size.height))
    }

    private func setupLoadingView() {
        loadingLabel.text = "Loading nearby locations..."
        loadingLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        loadingLabel.textColor = .gray
        loadingLabel.textAlignment = .center
        loadingLabel.frame = view.bounds
        loadingLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .none
        if #available(iOS 13.0, *) {
            tableView.backgroundColor = .systemBackground
        } else {
            tableView.backgroundColor = .white
        }
        tableView.backgroundView = mapView
    }

    private func setupMapView() {
        if #available(iOS 13.0, *) {
            searchController.searchBar.searchTextField.backgroundColor = .white
        } else {
            // Fallback on earlier versions
        }
        mapView = Map(frame: CGRect(origin: CGPoint(x: 0,y :0),
                                       size: CGSize(width: view.bounds.size.width,
                                                    height: view.bounds.size.height)))
        let startCoordinates = CLLocationCoordinate2D(latitude: NYCCoordinates.latitude,
                                                      longitude: NYCCoordinates.longitude)
        mapView?.setupMapRegion(startCoordinates: startCoordinates, radius: 3000)
    }

    private func getLocations() {
        let bundledLocations = DataProvider.getBundledLocations()
        appendLocations(bundledLocations)
        updateMap(withLocations: bundledLocations)

        DataProvider.getFireBoxes { [weak self] (fireBoxes) in
            self?.fireBoxes = fireBoxes.filter { !$0.boxNumber.isEmpty }
        }
        
        DataProvider.getEMSStations { [weak self] (emsStations) in
            self?.appendLocations(emsStations)
            self?.updateMap(withLocations: emsStations)
        }
        
        let boroughs: [NYCBoroughs] = [.statenIsland, .queens, .manhattan, .brooklyn, .bronx]
        for borough in boroughs {
            DataProvider.getFirehouses(forBorough: borough, completionHandler: { [weak self] (firehouses) in
                self?.appendLocations(firehouses)
                self?.updateMap(withLocations: firehouses)
            })
        }
        showNoResult(true)
    }

    private func appendLocations(_ newLocations: [Location]) {
        for location in newLocations {
            let key = locationKey(for: location)
            guard !loadedLocationKeys.contains(key) else { continue }
            loadedLocationKeys.insert(key)
            locations.append(location)
        }
    }

    private func locationKey(for location: Location) -> String {
        let latitude = location.latitude ?? 0
        let longitude = location.longitude ?? 0
        return "\(location.name)|\(location.address)|\(latitude)|\(longitude)"
    }

    private func setupNavigationBar() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Box number"
        searchController.searchBar.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.keyboardType = .numberPad
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController = searchController
        UINavigationBar.appearance().isTranslucent = false
        
       
        
        //ios15
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
            navigationController?.navigationBar.standardAppearance = appearance;
            navigationController?.navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
        } else {
            // Fallback on earlier versions
            navigationController?.navigationBar.barTintColor = .white
            navigationController?.navigationBar.tintColor = .red
        }
        
        let infoImage: UIImage?
        let addressSearchImage: UIImage?
        let mapImage: UIImage?
        if #available(iOS 13.0, *) {
            infoImage = UIImage(systemName: "info.circle")
            addressSearchImage = UIImage(systemName: "location.magnifyingglass")
            mapImage = UIImage(systemName: "map")
        } else {
            infoImage = UIImage(named:"Info")
            addressSearchImage = nil
            mapImage = nil
        }

        let infoButton = UIBarButtonItem(image: infoImage, style: .plain, target: self, action: #selector(onInfoButton(_:)))
        searchNavButton = UIBarButtonItem(image: addressSearchImage, style: .plain, target: self, action: #selector(searchByAddressTapped))
        searchNavButton?.title = "Address"
        mapNavButton = UIBarButtonItem(image: mapImage, style: .plain, target: self, action: #selector(onMapButton(_:)))
        mapNavButton?.title = "Map"

        navigationController?.navigationBar.tintColor = .systemRed
        self.navigationItem.leftBarButtonItems = [infoButton]
        self.navigationItem.rightBarButtonItems = [searchNavButton!, mapNavButton!]
    }

    private func showNoResult(_ shouldShow: Bool) {
        let shouldShowMap = searchController.searchBar.text?.isEmpty ?? true
            || searchController.searchBar.text ?? "" == kStartQuery
        tableView.backgroundView = shouldShowMap ? mapView : noResultsLabel
        tableView.backgroundView?.isHidden = !shouldShow

        navigationItem.rightBarButtonItems = shouldShowMap ? [searchNavButton!] : [searchNavButton!, mapNavButton!]
    }

    private func clearSearch() {
        filteredBoxes.removeAll()
        tableView.reloadData()
        showNoResult(filteredBoxes.isEmpty)
    }

    private func filter(searchQuery: String? ) {
        guard let searchText = searchQuery, searchText.count == maxQueryLength() else {
            return
        }

        let filteredBoxes = fireBoxes.filter { (box) -> Bool in
            return box.boxNumber == searchText
        }

        self.filteredBoxes = filteredBoxes
        showNoResult(filteredBoxes.isEmpty)
        tableView.reloadData()
    }

    private func maxQueryLength() -> Int {
        return 4
    }

    private func updateMap(withLocations locations: [Location]) {
        for location in locations {
            mapView?.addMarker(toLocation: location, color: .red)
        }
    }

    private func removeLeadingZero(searchText: String) -> String {
        if searchText.count > maxQueryLength() && searchText.first == "0" {
            let startIndex = searchText.index(searchText.startIndex, offsetBy: 1)
            return String(describing: searchText[startIndex...])
        }

        let endIndex = searchText.index(searchText.startIndex, offsetBy: 3)
        return String(describing: searchText[...endIndex])
    }

    private func addLeadingZero(searchText: String) -> String {
        if searchText.isEmpty { return kStartQuery }
        let end = searchText.index(searchText.endIndex, offsetBy: -1)
        var newText = String(describing: searchText[..<end])
        while newText.count < 4 {
            newText = "0" + newText
        }
        return newText
    }

    func getSearchQuery(text: String, newText: String, range: NSRange) -> String {
        if (range.length == 1 && newText.count == 0) {
            return addLeadingZero(searchText: text)
        }

        return removeLeadingZero(searchText: text.appending(newText))
    }

    // MARK: Actions
    @objc private func onInfoButton(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let settings = UIAlertAction(title: "Settings", style: .default) { [weak self] (action) in
            self?.onSettingsButton()
        }
        
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

        let fdnewyork = UIAlertAction(title: "FDNewYork", style: .default) { [weak self] (action) in
            self?.open(url: NetworkConstants.InfoURL.fdNewYork)
        }
        
        let shareAction = UIAlertAction(title: "SHARE APP", style: .default) { [weak self] (action) in
            let activityViewController = UIActivityViewController(
                activityItems: ["Check out the NYCFireBox App!", URL(string:NetworkConstants.InfoURL.share)!],
                applicationActivities: nil)
            self?.present(activityViewController, animated: true, completion: nil)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(settings)
        actionSheet.addAction(contact)
        actionSheet.addAction(website)
        actionSheet.addAction(liveIncidents)
        actionSheet.addAction(mobile)
        actionSheet.addAction(fdnewyork)
        actionSheet.addAction(shareAction)
        actionSheet.addAction(cancel)

        _ = resignFirstResponder()
        searchController.isActive = false
        setActionSheet(actionSheet: actionSheet)

        present(actionSheet, animated: true, completion: nil)
    }
    
    func onSettingsButton() {
        let actionSheet = UIAlertController(title: "Push Notifications", message: nil, preferredStyle: .actionSheet)
        let defaults = UserDefaults.standard
        let disablePushNotificationsKey = "disablePushNotifications"
        if defaults.bool(forKey: disablePushNotificationsKey) {
            actionSheet.addAction(UIAlertAction(title: "Enable Push Notifications", style: .default, handler: { (action) in
                defaults.set(false, forKey: disablePushNotificationsKey)
#if canImport(OneSignalFramework)
                OneSignal.User.pushSubscription.optIn()
#endif
            }))
        } else {
            actionSheet.view.tintColor = UIColor.red
            actionSheet.addAction(UIAlertAction(title: "Disable Push Notifications", style: .default, handler: { (action) in
                defaults.set(true, forKey: disablePushNotificationsKey)
#if canImport(OneSignalFramework)
                OneSignal.User.pushSubscription.optOut()
#endif
            }))
        }
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
        }))
        
        setActionSheet(actionSheet: actionSheet)
        
        _ = resignFirstResponder()
        searchController.isActive = false
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
        guard !locations.isEmpty else {
            tableView.backgroundView = loadingLabel
            return
        }
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
        searchBar.text = getSearchQuery(text: searchBar.text ?? "", newText: text, range: range)
        return false
    }

     func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.text = kStartQuery
        return true
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchBar.text ?? "").isEmpty {
            searchBar.text = kStartQuery
        }
    }
}

extension SearchViewController {
    @IBAction func searchByAddressTapped() {
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Find nearby boxes", message: "Enter a full street address.", preferredStyle: .alert)

        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.placeholder = "Address"
            textField.textContentType = .fullStreetAddress
        }

        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "Search", style: .default, handler: { [weak alert] (_) in
            if let text = alert?.textFields?[0].text {
                self.searchAddress(address: text)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    func searchAddress(address: String) {
        let geoCoder = CLGeocoder()

        geoCoder.geocodeAddressString(address) { [weak self] (placemarks, error) in
            if error == nil {
                
                if let longitude = placemarks?.first?.location?.coordinate.longitude,
                    let latitude = placemarks?.first?.location?.coordinate.latitude {
                    let myLocation = CLLocation(latitude: latitude, longitude: longitude)
                    self?.locations.append((Location(name: "Searched Address", address: address, borough: nil, area: nil, longitude: longitude, latitude: latitude)))
                    var boxes = self?.fireBoxes
                    
                    boxes?.sort(by: { $0.distance(to: myLocation) < $1.distance(to: myLocation) })
                    
                    if let self = self, let nearestBoxes = boxes {
                        self.filteredBoxes = Array(nearestBoxes.prefix(4))
                        self.showNoResult(false)
                        self.tableView.reloadData()
                        self.navigationItem.rightBarButtonItems = [self.searchNavButton!, self.mapNavButton!]
                    }

                }
                

            } else {
                self?.showAddressSearchError()
            }
        }

    }

    private func showAddressSearchError() {
        let alert = UIAlertController(title: "Address not found",
                                      message: "Check the address and try again.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
