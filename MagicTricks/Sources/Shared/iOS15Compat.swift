import SwiftUI

// These thin wrappers exist so call sites don't need to be touched.
// Deployment target is iOS 16 — APIs are called directly.

extension View {
    func withPresentationDragIndicator() -> some View {
        self.presentationDragIndicator(.visible)
    }
    func hideScrollIndicators() -> some View {
        self.scrollIndicators(.hidden)
    }
    func hideScrollContentBackground() -> some View {
        self.scrollContentBackground(.hidden)
    }
}
