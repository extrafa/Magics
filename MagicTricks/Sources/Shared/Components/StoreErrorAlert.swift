//
//  StoreErrorAlert.swift
//  Magic Tricks
//

import SwiftUI

extension View {
    func storeErrorAlert(_ store: StoreManager) -> some View {
        alert(
            String(localized: "common.error"),
            isPresented: Binding(
                get: { store.alertMessage != nil },
                set: { if !$0 { store.alertMessage = nil } }
            )
        ) {
            Button(String(localized: "common.ok")) { store.alertMessage = nil }
        } message: {
            Text(store.alertMessage ?? "")
        }
    }
}
