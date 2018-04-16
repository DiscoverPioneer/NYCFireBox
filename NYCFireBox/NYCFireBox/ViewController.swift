import UIKit
import MapKit

class ViewController: UIViewController {
    private var fireBoxes: [FireBox] = []
    private var filteredBoxes: [FireBox] = []
    private var searchController = UISearchController(searchResultsController: nil)
    @IBOutlet var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
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
        guard let filePath = Bundle.main.path(forResource: "Fire Boxes", ofType: "csv") else { return }
        let contents = try? String(contentsOfFile: filePath, encoding: .utf8)
        let rows = contents?.components(separatedBy: "\n")
        for row in rows ?? [] {
            fireBoxes.append(FireBox(string: row))
        }
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
        let location = box.location()
        let regionDistance: CLLocationDistance = 500
        let locationCoordinates = location.coordinate
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

