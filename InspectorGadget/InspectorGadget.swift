/*
InspectorGadget SDK Explanation:

This SDK is like a little helper that watches your app and tells you whenever some words on the screen change. It looks at all the things you can see in your app (like labels and buttons) and listens for when their text changes. It also watches special hidden labels that help people who use accessibility tools. When it sees something change, it writes a message in the console so you know what changed and where. You just need to add one line to your app to turn it on, and it will start watching for you. You don't have to change your main screen code at all.
*/

import UIKit // UIKit is the toolbox for building iOS apps with views, windows, and controls.
import ObjectiveC.runtime // This lets us do "magic tricks" like swapping out methods at runtime.
import SwiftUI // SwiftUI is a newer way to build user interfaces in iOS.

// This is the main helper class. It starts everything and keeps track of changes.
@objc public class InspectorGadgetCore: NSObject {
    // This is like a notebook where we remember the last words we saw for each thing.
    // ObjectIdentifier is a way to give every object a unique name, like a nametag.
    private static var lastLabels: [ObjectIdentifier: String] = [:]

    // This is the button you press to start the helper. Usually, the app presses it for you.
    @objc public static func start() {
        print("[InspectorGadget] Initialized.")
        swizzleUILabel() // We swap out the way labels set their text so we can listen for changes.
        _ = OverlayWindow.shared // We make a special invisible window to help us catch changes from SwiftUI.
        startAccessibilityPolling() // We start looking for changes in the words that help with accessibility.
    }

    // This is a magic trick (called swizzling) that lets us listen whenever a label's text changes in UIKit.
    private static func swizzleUILabel() {
        // We try to get the real method that sets the text on a UILabel.
        guard
            let originalMethod = class_getInstanceMethod(UILabel.self, #selector(setter: UILabel.text)),
            // We also get our own special method that will do the same thing, but also tell us when it happens.
            let swizzledMethod = class_getInstanceMethod(UILabel.self, #selector(UILabel.qm_setText(_:)))
        else {
            print("[InspectorGadget] Swizzling failed.")
            return
        }
        // We swap the real setText with our own version, so whenever someone sets the text, we get to listen in.
        method_exchangeImplementations(originalMethod, swizzledMethod)
        print("[InspectorGadget] UILabel.text swizzling complete.")
    }

    // If you want to tell the helper about some new words yourself, you can use this.
    public static func logSwiftUIText(_ text: String) {
        // This tells our invisible label (in OverlayWindow) to update its text.
        OverlayWindow.shared.updateText(text)
    }

    // This starts a timer that checks every half a second to see if any words have changed.
    public static func startAccessibilityPolling() {
        // Timer.scheduledTimer makes a clock that ticks every 0.5 seconds (half a second).
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            // We look at every "scene" (like a page or window) in the app.
            for scene in UIApplication.shared.connectedScenes {
                // We only care about scenes that are windows (where things are shown on screen).
                if let windowScene = scene as? UIWindowScene {
                    // Each scene can have many windows (like layers of glass you can see through).
                    for window in windowScene.windows {
                        // We check every window for changes in the words.
                        updateAndLogAccessibilityLabels(in: window)
                    }
                }
            }
        }
    }

    // This is like walking through a big house (the app's view tree) and checking every room (view) for new words.
    private static func updateAndLogAccessibilityLabels(in view: UIView) {
        // Some rooms have special notes (accessibility elements) for people who need help reading the screen.
        if let elements = view.accessibilityElements as? [NSObject], !elements.isEmpty {
            for element in elements {
                // If we find a note with words, we check if it's new.
                if let accLabel = element.value(forKey: "accessibilityLabel") as? String, !accLabel.isEmpty {
                    let id = ObjectIdentifier(element) // Give this note a unique name.
                    // If the words are different from last time, we write them down and tell you.
                    if lastLabels[id] != accLabel {
                        lastLabels[id] = accLabel
                        print("[InspectorGadget] Accessibility text changed: '" + accLabel + "' on element: " + String(describing: element))
                    }
                }
            }
        }
        // We keep walking into every room inside this room (all subviews).
        for subview in view.subviews {
            updateAndLogAccessibilityLabels(in: subview)
        }
    }

    private static func printViewHierarchy(_ view: UIView, indent: String = "") {
        print("\(indent)\(type(of: view)): \(view.accessibilityLabel ?? "nil")")
        if let elements = view.accessibilityElements as? [NSObject], !elements.isEmpty {
            for element in elements {
                if let accLabel = element.value(forKey: "accessibilityLabel") as? String {
                    print("\(indent)  [Element] \(type(of: element)): \(accLabel)")
                } else {
                    print("\(indent)  [Element] \(type(of: element)): (no label)")
                }
            }
        }
        for subview in view.subviews {
            printViewHierarchy(subview, indent: indent + "  ")
        }
    }
}
