//
//  CustomerCenterSheetView.swift
//  ChallengeNegocios
//
//  RevenueCat Customer Center — lets subscribers manage, cancel, and
//  restore purchases without leaving the app.
//  Requires a RevenueCat Pro or Enterprise plan.
//

import SwiftUI
import RevenueCatUI

// MARK: - CustomerCenterSheetView

/// Wraps RevenueCatUI's `CustomerCenterView` with a navigation chrome.
struct CustomerCenterSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        CustomerCenterView()
    }
}

// MARK: - View Modifier (convenience)

extension View {

    /// Presents Customer Center as a sheet when `isPresented` is true.
    func customerCenterSheet(isPresented: Binding<Bool>) -> some View {
        self.presentCustomerCenter(isPresented: isPresented)
    }
}
