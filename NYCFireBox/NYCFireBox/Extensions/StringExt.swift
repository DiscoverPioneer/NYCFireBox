import Foundation
import UIKit

extension String  {
    var isNumeric : Bool {
        get{
            return !self.isEmpty && self.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil
        }
    }
}
