import Foundation
import UIKit

// This is a trick we use to listen for when a label's text changes in UIKit.
public extension UILabel {
    // This is our special version of setting the text. It lets us know when the words change.
    @objc func qm_setText(_ text: String?) {
        // If the label already had some words, and now the words are different, we tell you what changed.
        if let oldText = self.text, let newText = text, oldText != newText {
            print("[InspectorGadget] UILabel text changed: '" + oldText + "' -> '" + newText + "'")
        } else if let newText = text {
            // If the label is getting words for the first time, we tell you.
            print("[InspectorGadget] UILabel set: '" + newText + "'")
        }
        // We still do the real work of setting the text, so the label updates on screen.
        self.qm_setText(text)
    }
}
