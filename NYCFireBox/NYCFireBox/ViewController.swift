import UIKit

class ViewController: UIViewController {
    private var fireBoxes: [FireBox] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        getLocations()
        
    }

    private func setupViews() {

    }

    private func getLocations() {
        guard let filePath = Bundle.main.path(forResource: "Fire Boxes", ofType: "csv") else { return }
        let contents = try? String(contentsOfFile: filePath, encoding: .utf8)
        let rows = contents?.components(separatedBy: "\n")
        for row in rows ?? [] {
            fireBoxes.append(FireBox(string: row))
        }
    }
}

