//
//  ProBadgeView.swift
//  ChallengeNegocios
//
//  Reusable UI components for displaying subscription status
//  and an "Upgrade to Pro" button.
//

import SwiftUI
import RevenueCat

// MARK: - ProBadge

/// Small inline badge shown next to the user's name / in the nav bar
/// when they have an active "Zipit, go Pro" subscription.
struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.caption2)
            .fontWeight(.black)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                LinearGradient(
                    colors: [Color.purple, Color.blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
    }
}

// MARK: - UpgradeButton

/// Prominent CTA button that opens the paywall.
struct UpgradeButton: View {
    @Binding var showPaywall: Bool

    var body: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                Text("Upgrade to Pro")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color.purple, Color.blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
        }
    }
}

// MARK: - SubscriptionStatusView

/// Displays the user's full subscription status: active plan, renewal date,
/// manage-subscription button, and restore-purchases button.
struct SubscriptionStatusView: View {
    @State private var manager = SubscriptionManager.shared
    @State private var showCustomerCenter = false
    @State private var showPaywall = false
    @State private var restoreMessage: String?

    var body: some View {
        List {
            // ── Status section ──────────────────────────────────────────
            Section("Plan") {
                if manager.isPro {
                    HStack {
                        Label("Zipit, go Pro", systemImage: "star.fill")
                            .foregroundStyle(.purple)
                        Spacer()
                        ProBadge()
                    }

                    if let expiry = manager.customerInfo?
                        .entitlements[manager.entitlementID]?.expirationDate {
                        Label(
                            "Renews \(expiry.formatted(date: .abbreviated, time: .omitted))",
                            systemImage: "arrow.clockwise"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                } else {
                    Label("Free Plan", systemImage: "lock.fill")
                    UpgradeButton(showPaywall: $showPaywall)
                        .listRowBackground(Color.clear)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }

            // ── Actions section ──────────────────────────────────────────
            Section("Account") {
                if manager.isPro {
                    Button {
                        showCustomerCenter = true
                    } label: {
                        Label("Manage Subscription", systemImage: "creditcard")
                    }
                }

                Button {
                    Task { await restore() }
                } label: {
                    if manager.isLoading {
                        ProgressView()
                    } else {
                        Label("Restore Purchases", systemImage: "arrow.counterclockwise")
                    }
                }
                .disabled(manager.isLoading)

                if let msg = restoreMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Subscription")
        .paywallSheet(isPresented: $showPaywall)
        .customerCenterSheet(isPresented: $showCustomerCenter)
        .alert("Error", isPresented: .constant(manager.error != nil), actions: {
            Button("OK") { }
        }, message: {
            Text(manager.error?.localizedDescription ?? "")
        })
    }

    private func restore() async {
        do {
            let info = try await manager.restorePurchases()
            restoreMessage = info.activeSubscriptions.isEmpty
                ? "No active purchases found."
                : "Purchases restored successfully!"
        } catch {
            restoreMessage = "Restore failed: \(error.localizedDescription)"
        }
    }
}
