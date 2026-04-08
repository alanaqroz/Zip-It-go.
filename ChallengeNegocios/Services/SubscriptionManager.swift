//
//  SubscriptionManager.swift
//  ChallengeNegocios
//
//  RevenueCat integration — subscription state, purchases & restores.
//

import RevenueCat
import SwiftUI

// MARK: - SubscriptionManager

@Observable
final class SubscriptionManager {

    // ── Singleton ──────────────────────────────────────────────────────────
    static let shared = SubscriptionManager()

    // ── Public state ───────────────────────────────────────────────────────
    /// Whether the current user has an active "Zipit, go Pro" entitlement.
    private(set) var isPro: Bool = false
    /// Latest CustomerInfo fetched from RevenueCat.
    private(set) var customerInfo: CustomerInfo?
    /// True while a network/purchase operation is in flight.
    private(set) var isLoading: Bool = false
    /// Last error surfaced from a purchase / restore call.
    private(set) var error: RevenueCatError?

    // ── Constants ──────────────────────────────────────────────────────────
    let entitlementID = "Zipit, go Pro"

    private init() {}

    // MARK: - Configure SDK

    /// Call once at app launch (inside `App.init()`).
    func configure() {
        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        Purchases.configure(withAPIKey: "test_pWddoaslGvNWiCfFiKVXJdHpNzc")

        // Warm up local state
        Task { await refreshCustomerInfo() }

        // Stream real-time updates (e.g. subscription renewed in background)
        Task {
            for await info in Purchases.shared.customerInfoStream {
                await updateState(from: info)
            }
        }
    }

    // MARK: - Read customer info

    /// Fetches the latest CustomerInfo from RevenueCat and updates local state.
    @MainActor
    func refreshCustomerInfo() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let info = try await Purchases.shared.customerInfo()
            updateState(from: info)
        } catch {
            self.error = RevenueCatError(underlying: error)
        }
    }

    // MARK: - Purchase

    /// Purchases a single `Package` from an Offering.
    @MainActor
    @discardableResult
    func purchase(package: Package) async throws -> CustomerInfo {
        isLoading = true
        defer { isLoading = false }
        error = nil

        let result = try await Purchases.shared.purchase(package: package)
        updateState(from: result.customerInfo)
        return result.customerInfo
    }

    // MARK: - Restore

    /// Restores previous purchases (required by App Store guidelines).
    @MainActor
    @discardableResult
    func restorePurchases() async throws -> CustomerInfo {
        isLoading = true
        defer { isLoading = false }
        error = nil

        let info = try await Purchases.shared.restorePurchases()
        updateState(from: info)
        return info
    }

    // MARK: - Offerings

    /// Loads the current Offering configured on the RevenueCat dashboard.
    func currentOffering() async throws -> Offering? {
        let offerings = try await Purchases.shared.offerings()
        return offerings.current
    }

    // MARK: - Private helpers

    @MainActor
    private func updateState(from info: CustomerInfo) {
        customerInfo = info
        isPro = info.entitlements[entitlementID]?.isActive == true
    }
}

// MARK: - RevenueCatError (lightweight wrapper)

struct RevenueCatError: LocalizedError {
    let underlying: Error
    var errorDescription: String? { underlying.localizedDescription }
}
