import Foundation
import UIKit

class SearchQueryFormatter {
    private let appLocation: AppLocation

    let startQuery: String
    let maxQueryLength: Int
    let keyboardType: UIKeyboardType

    init(appLocation: AppLocation) {
        self.appLocation = appLocation
        switch appLocation {
        case .NYC:
            startQuery = "0000"
            maxQueryLength = 4
            keyboardType = .numberPad
        case .Boston:
            startQuery = ""
            maxQueryLength = 7
            keyboardType = .numbersAndPunctuation
        }
    }

    func applyFormat(toQuery query:  String) -> String {
        if query.isEmpty { return startQuery }
        let end = query.index(query.endIndex, offsetBy: -1)
        var newText = String(describing: query[..<end])
        while newText.count < maxQueryLength {
            newText = "0" + newText
        }
        return newText
    }

    func removeFormat(fromQuery query: String) -> String {
        if query.count > maxQueryLength && query.first == "0" {
            let startIndex = query.index(query.startIndex, offsetBy: 1)
            return String(describing: query[startIndex...])
        }

        let endIndex = query.index(query.startIndex, offsetBy: maxQueryLength - 1)
        return String(describing: query[...endIndex])
    }

    func getSearchQuery(text: String, newText: String, range: NSRange) -> String {

        if !isValid(string: text.appending(newText)) { return text }

        switch appLocation {
        case .NYC:
            if (range.length == 1 && newText.count == 0) {
                return applyFormat(toQuery: text)
            }

            return removeFormat(fromQuery: text.appending(newText))
        case .Boston:
            if (range.length == 1 && newText.count == 0) {
                return trim(text: text)
            }

           return text.appending(newText).count > maxQueryLength ? text : text.appending(newText)
        }
    }

    func isValid(query: String) -> Bool {
        switch appLocation {
        case .Boston: return query.count > 0
        case .NYC: return query.count == maxQueryLength
        }
    }

    private func isValid(character: String) -> Bool {
        return character.isNumeric || character == "-" || character == ""
    }

    private func isValid(string: String) -> Bool {
        if string.count > maxQueryLength { return false }

        let validCount = string.filter {$0 == "-"}.count <= 1

        var validPlacement = string.index(of: "-") == nil
        if string.index(of: "-") != nil && string.count > 2 {
            validPlacement = string.index(of: "-") == string.index(string.startIndex, offsetBy: 2)
        }

        for character in string {
            if !isValid(character: String(describing: character)) { return false }
        }

        return validCount && validPlacement
    }

    private func trim(text: String) -> String {
        var trimmedText = text
        if !text.isEmpty {
            trimmedText.removeLast()
        }

        return trimmedText
    }
}
