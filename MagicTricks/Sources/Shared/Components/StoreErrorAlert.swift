//
//  StoreErrorAlert.swift
//  Magic Tricks
//

import SwiftUI

extension View {
    func storeErrorAlert(_ storeAlert: Binding<StoreAlert?>) -> some View {
        alert(
            storeAlert.wrappedValue?.title ?? "",
            isPresented: Binding(
                get: { storeAlert.wrappedValue != nil },
                set: { if !$0 { storeAlert.wrappedValue = nil } }
            )
        ) {
            Button(String(localized: "common.ok")) { storeAlert.wrappedValue = nil }
        } message: {
            Text(storeAlert.wrappedValue?.message ?? "")
        }
    }
}
