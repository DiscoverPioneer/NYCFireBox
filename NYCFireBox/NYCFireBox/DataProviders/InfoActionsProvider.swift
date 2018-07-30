import Foundation
import UIKit
import OneSignal

class InfoActionsProvider {
    private let constants = Constants()

    func getAlertActions() -> [UIAlertAction] {
        switch constants.appLocation {
        case .Boston: return [contactAction(), websiteAction(), NYCFireBoxAction(), shareAction(), cancelAction()]
        case .NYC: return [settingsAction(), contactAction(), websiteAction(), liveIncidentsAction(), mobileMDTAction(), firedepAction(), shareAction(), cancelAction()]
        }
    }

    fileprivate func contactAction() -> UIAlertAction {
        guard  let contactURL = constants.contactURL else { return UIAlertAction() }
        return UIAlertAction(title: "Contact Us", style: .default) { [weak self] (action) in
            self?.open(email: contactURL)
        }
    }

    fileprivate func websiteAction() -> UIAlertAction {
        guard  let websiteURL = constants.websiteURL else { return UIAlertAction() }
        return UIAlertAction(title: "Website", style: .default) { [weak self] (action) in
            self?.open(url: websiteURL)
        }
    }

    fileprivate func NYCFireBoxAction() -> UIAlertAction {
        guard  let NYCFireBoxURL = constants.linkedAppURL else { return UIAlertAction() }
        return UIAlertAction(title: "NYCFirebox", style: .default) { [weak self] (action) in
            self?.open(url: NYCFireBoxURL)
        }
    }

    fileprivate func mobileMDTAction() -> UIAlertAction {
        guard let mdtURL = constants.linkedAppURL else  { return UIAlertAction() }
        return UIAlertAction(title: "Mobile MDT", style: .default) { [weak self] (action) in
            self?.open(url: mdtURL)
        }
    }

    fileprivate func liveIncidentsAction() -> UIAlertAction {
        guard let incidentsURL = constants.liveincidentsURL else { return UIAlertAction() }
        return UIAlertAction(title: "Live Incidents", style: .default) { [weak self] (action) in
            self?.open(url: incidentsURL)
        }
    }

    fileprivate func firedepAction() -> UIAlertAction {
        guard let firedepURL = constants.firedepURL else  { return UIAlertAction() }
        return UIAlertAction(title: "FDNewYork", style: .default) { [weak self] (action) in
            self?.open(url: firedepURL)
        }
    }

    fileprivate func settingsAction() -> UIAlertAction {
        return UIAlertAction(title: "Settings", style: .default) { [weak self] (action) in
            self?.settings()
        }
    }

    fileprivate func shareAction() -> UIAlertAction {
        guard let share = constants.shareURL, let shareURL = URL(string: share) else { return UIAlertAction() }

        var title: String = ""
        switch constants.appLocation {
        case .Boston: title = "Check out the BostonFireBox App!"
        case .NYC: title = "Check out the NYCFireBox App!"
        }

        return UIAlertAction(title: "SHARE APP", style: .default) { (action) in
                        let activityViewController = UIActivityViewController(
                            activityItems: [title,  shareURL],
                            applicationActivities: nil)
            UIApplication.topMostController()?.present(activityViewController, animated: true, completion: nil)
        }
    }

    fileprivate func cancelAction() -> UIAlertAction {
        return UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    }

    private func settings() {
        let actionSheet = UIAlertController(title: "Push Notifications", message: nil, preferredStyle: .actionSheet)
        let defaults = UserDefaults.standard
        let disablePushNotificationsKey = "disablePushNotifications"
        if defaults.bool(forKey: disablePushNotificationsKey) {
            actionSheet.addAction(UIAlertAction(title: "Enable Push Notifications", style: .default, handler: { (action) in
                defaults.set(false, forKey: disablePushNotificationsKey)
                OneSignal.setSubscription(true)
            }))
        } else {
            actionSheet.view.tintColor = UIColor.red
            actionSheet.addAction(UIAlertAction(title: "Disable Push Notifications", style: .default, handler: { (action) in
                defaults.set(true, forKey: disablePushNotificationsKey)
                OneSignal.setSubscription(false)
            }))
        }
        actionSheet.addAction(cancelAction())

        setActionSheet(actionSheet: actionSheet)

        UIApplication.topMostController()?.present(actionSheet, animated: true, completion: nil)
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

    private func setActionSheet(actionSheet: UIAlertController) {
        if let popoverController = actionSheet.popoverPresentationController,
            let topController = UIApplication.topMostController() {
            popoverController.sourceView = topController.view
            popoverController.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
    }
}
