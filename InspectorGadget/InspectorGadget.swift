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

// This is a trick we use to listen for when a label's text changes in UIKit.
extension UILabel {
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

// This is a special invisible window we use to help catch changes from SwiftUI.
public class OverlayWindow {
    // We only want one of these, so we use a shared instance (like a single magic window for the whole app).
    public static let shared = OverlayWindow()
    private var window: UIWindow? // This is the actual invisible window.
    private let label = UILabel() // This is a hidden label we use for our magic trick.
    private var windowScene: UIWindowScene? // This is where our window lives (like a room in the house).

    // When we make the window, we also listen for when the app becomes active.
    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sceneDidConnect(notification:)),
            name: UIScene.didActivateNotification,
            object: nil
        )
        setupWindowIfPossible()
    }

    // When the app becomes active, we try to set up the window again.
    @objc private func sceneDidConnect(notification: Notification) {
        setupWindowIfPossible()
    }

    // This makes sure our window is attached to the right place in the app.
    private func setupWindowIfPossible() {
        if window != nil { return } // If we already made the window, don't do it again.
        // We look for a scene (room) that is active and in the front.
        guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            print("[OverlayWindow] No active UIWindowScene found yet")
            return
        }
        windowScene = scene
        setupWindow()
    }

    // This sets up the invisible window and puts our hidden label inside it.
    private func setupWindow() {
        guard let scene = windowScene else {
            print("[OverlayWindow] No UIWindowScene to setup window")
            return
        }
        // We make a new window and tell it which scene (room) it belongs to.
        let window = UIWindow(windowScene: scene)
        // window.frame is like the size and position of the window. We make it cover the whole screen.
        window.frame = UIScreen.main.bounds // UIScreen.main.bounds is the rectangle for the whole screen.
        // window.windowLevel decides how high up the window is. .statusBar + 1 means it's above the status bar, so it's on top of everything.
        window.windowLevel = .statusBar + 1 // Make sure it's on top
        // window.backgroundColor is the color behind everything in the window. We make it clear so you can't see it.
        window.backgroundColor = .clear
        // window.isHidden = false means the window is visible (but since it's clear, you still can't see it).
        window.isHidden = false
        // window.isUserInteractionEnabled = false means you can't tap or interact with this window.
        window.isUserInteractionEnabled = false
        // label.isHidden = true hides the label so users don't see it.
        label.isHidden = true
        // label.textColor = .clear makes the label's text invisible.
        label.textColor = .clear
        // We put the label inside the window, like putting a sticky note on a window.
        window.addSubview(label)
        // We remember our window so we can use it later.
        self.window = window
        print("[OverlayWindow] Window created successfully")
    }

    // This changes the text of our hidden label. It's a way for SwiftUI to tell UIKit about new words.
    public func updateText(_ text: String) {
        // We use DispatchQueue.main.async to make sure we change the label on the main thread (the one that updates the screen).
        DispatchQueue.main.async {
            self.label.text = text
        }
    }
}

// This is a special SwiftUI tool that lets you turn on InspectorGadgetCore with just one line.
public struct InspectorGadgetModifier: ViewModifier {
    public init() {}
    public func body(content: Content) -> some View {
        // When your app's main screen appears, we start the helper.
        content.onAppear {
            InspectorGadgetCore.start()
        }
    }
}

// This is a shortcut so you can just write .inspectorGadget() in your SwiftUI code.
public extension View {
    func inspectorGadget() -> some View {
        self.modifier(InspectorGadgetModifier())
    }
}

#if DEBUG
// This extension is only available in test builds. It lets tests check the label's text.
extension OverlayWindow {
    var test_labelText: String? { label.text }
}
#endif
