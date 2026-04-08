//
//  AppPaywallView.swift
//  ChallengeNegocios
//
//  Thin wrapper around RevenueCatUI's PaywallView.
//  The actual paywall template / copy is configured on the RevenueCat dashboard —
//  no code changes needed when you update it there.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

// MARK: - AppPaywallView

/// Full-screen paywall backed by the current Offering on the dashboard.
/// Dismiss via the built-in close button or `dismiss` environment action.
struct AppPaywallView: View {

    /// Optional: pass a specific offering; defaults to the current one.
    var offering: Offering? = nil

    var body: some View {
        if let offering {
            PaywallView(offering: offering, displayCloseButton: true)
        } else {
            PaywallView(displayCloseButton: true)
        }
    }
}

// MARK: - View Modifiers (convenience)

extension View {

    /// Presents the paywall as a sheet when `isPresented` is true.
    func paywallSheet(isPresented: Binding<Bool>, offering: Offering? = nil) -> some View {
        self.sheet(isPresented: isPresented) {
            AppPaywallView(offering: offering)
        }
    }

    /// Presents the paywall as a full-screen cover when `isPresented` is true.
    func paywallFullScreen(isPresented: Binding<Bool>, offering: Offering? = nil) -> some View {
        self.fullScreenCover(isPresented: isPresented) {
            AppPaywallView(offering: offering)
        }
    }

    /// Automatically shows the paywall whenever the required entitlement is absent.
    /// Uses RevenueCatUI's built-in modifier — no manual tracking required.
    func requiresProEntitlement() -> some View {
        self.presentPaywallIfNeeded(
            requiredEntitlementIdentifier: SubscriptionManager.shared.entitlementID,
            purchaseCompleted: { customerInfo in
                // Optional: track the event in PostHog / analytics here
                print("Purchase completed: \(customerInfo.activeSubscriptions)")
            },
            restoreCompleted: { customerInfo in
                print("Restore completed: \(customerInfo.activeSubscriptions)")
            }
        )
    }
}
