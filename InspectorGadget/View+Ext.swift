import SwiftUI

// This is a shortcut so you can just write .inspectorGadget() in your SwiftUI code.
public extension View {
    func inspectorGadget() -> some View {
        self.modifier(InspectorGadgetModifier())
    }
}

