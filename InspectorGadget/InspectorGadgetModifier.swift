import SwiftUI

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
