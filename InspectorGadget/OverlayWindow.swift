import UIKit
import SwiftUI

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

#if DEBUG
// This extension is only available in test builds. It lets tests check the label's text.
extension OverlayWindow {
    var test_labelText: String? { label.text }
}
#endif
