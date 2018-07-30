import Foundation
import UIKit

extension UIApplication {
    class func topMostController() -> UIViewController? {
        let appDelegate = shared.delegate as! AppDelegate
        let window = appDelegate.window
        return findPresentedViewController(window?.rootViewController)
    }

    class func findPresentedViewController(_ base: UIViewController?) -> UIViewController? {
        if let navigationController = base as? UINavigationController,
            let visibleController = navigationController.visibleViewController {
            return findPresentedViewController(visibleController)
        }
  
        if let presentedController = base?.presentedViewController {
            return findPresentedViewController(presentedController)
        }
        return base
    }
}
