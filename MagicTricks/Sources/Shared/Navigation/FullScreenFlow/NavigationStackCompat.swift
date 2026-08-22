//
//  NavigationStackCompat.swift
//  Magic Tricks
//
//  iOS 15 compatibility shim for NavigationStack.
//

import SwiftUI

// Wrapper that isolates the iOS 16 type so the compiler
// doesn't raise availability errors at call sites.
@available(iOS 16, *)
private struct _NavStack16<Content: View>: View {
    let content: () -> Content
    var body: some View { NavigationStack(root: content) }
}

struct NavigationStackCompat<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        if #available(iOS 16, *) {
            _NavStack16(content: content)
        } else {
            NavigationView(content: content)
                .navigationViewStyle(.stack)
        }
    }
}
