//
//  CustomPaywallView.swift
//  ChallengeNegocios
//

import SwiftUI
import RevenueCat

// MARK: - CustomPaywallView

struct CustomPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIndex: Int = 0
    @State private var packages: [Package] = []
    @State private var isLoading = false
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    
    private var manager = SubscriptionManager.shared

    private let fallbackPlans: [(title: String, price: String, period: String?, bestDeal: Bool)] = [
        ("Lifetime", "$ 49,99", nil, true),
        ("Monthly", "$ 4,99", "/ Month", false),
        ("Yearly", "$ 19,99", "/ Year", false),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                //  Botão fechar
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color(.systemGray6)))
                }
                .padding(.top, 16)
                .padding(.leading, 20)

                // ── Título
                VStack(alignment: .center, spacing: 0) {
                    Text("Pack smarter\nwith ")
                        .font(.system(size: 40, weight: .black))
                        .foregroundColor(.primary)
                    + Text("Zip It!")
                        .font(.system(size: 40, weight: .black))
                        .foregroundColor(Color("Button"))
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
                .padding(.horizontal, 24)

                // ── O que você ganha ─────────────────────────────────────────
                VStack(alignment: .leading, spacing: 20) {
                    Text("What you get:")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.primary)

                    FeatureRow(icon: "cloud.rain.fill", text: "Smart packing lists based on destination & weather")
                    FeatureRow(icon: "checkmark.circle.fill", text: "Real-time checklist. Check off items as you pack.")
                    FeatureRow(icon: "suitcase.fill", text: "Unlimited trips. Organize all your travels!")
                }
                .padding(.horizontal, 30)
                .padding(.top, 30)

                // ── Planos
                VStack(spacing: 16) {
                    ForEach(fallbackPlans.indices, id: \.self) { i in
                        let p = fallbackPlans[i]
                        PlanCard(
                            title: p.title,
                            price: p.price,
                            period: p.period,
                            isBestDeal: p.bestDeal,
                            isSelected: selectedIndex == i
                        ) { selectedIndex = i }
                    }
//                    if packages.isEmpty {
//                        ForEach(fallbackPlans.indices, id: \.self) { i in
//                            let p = fallbackPlans[i]
//                            PlanCard(
//                                title: p.title,
//                                price: p.price,
//                                period: p.period,
//                                isBestDeal: p.bestDeal,
//                                isSelected: selectedIndex == i
//                            ) { selectedIndex = i }
//                        }
//                    } else {
//                        ForEach(packages.indices, id: \.self) { i in
//                            let pkg = packages[i]
//                            PlanCard(
//                                title: pkg.storeProduct.localizedTitle,
//                                price: pkg.storeProduct.localizedPriceString,
//                                period: periodLabel(for: pkg),
//                                isBestDeal: pkg.packageType == .lifetime,
//                                isSelected: selectedIndex == i
//                            ) { selectedIndex = i }
//                        }
//                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)

                // Botão de Inscrição
                Button {
                    Task { await comprar() }
                } label: {
                    ZStack {
                        if isPurchasing {
                            ProgressView().tint(Color(.systemBackground))
                        } else {
                            Text("Subscribe to Pro")
                                .font(.headline)
                                .fontWeight(.bold)
                                // white in light mode, black in dark mode
                                .foregroundStyle(Color(.systemBackground))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color("Button"))
                    .clipShape(Capsule())
                }
                .disabled(isPurchasing)
                .padding(.horizontal, 24)
                .padding(.top, 32)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                }

                // ── Rodapé
                HStack {
                    Button("Restore Purchases") {
                        Task { await restaurar() }
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        openURL("https://time-mare-9c9.notion.site/Terms-Conditions-EULA-33e73c91fe7b806ba953f81a0e124d83")
                    } label: {
                        Text("Terms of Use (EULA)")
                            .font(.system(size: 12, weight: .semibold))
                            .underline()
                            .foregroundStyle(Color("Button"))
                    }

                    Spacer()

                    Button("Privacy Policy") {
                        openURL("https://pond-copper-f2d.notion.site/Privacy-Policy-33ec184f41378005970bf436a8ecf0eb?pvs=73")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 30)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .task { await carregarPacotes() }
    }

    // MARK: - Funções de Lógica (RevenueCat)

    private func carregarPacotes() async {
        do {
            if let offering = try await manager.currentOffering() {
                // Ordena os pacotes conforme necessário
                let pkgs = offering.availablePackages
                let lifetime = pkgs.filter { $0.packageType == .lifetime }
                let monthly = pkgs.filter { $0.packageType == .monthly }
                let yearly = pkgs.filter { $0.packageType == .annual }
                
                self.packages = lifetime + monthly + yearly
            }
        } catch {
            print("Erro ao carregar pacotes: \(error)")
        }
    }

    private func comprar() async {
        guard !packages.isEmpty else { return }
        isPurchasing = true
        errorMessage = nil
        
        let pkg = packages[selectedIndex]
        
        do {
            try await manager.purchase(package: pkg)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isPurchasing = false
    }

    private func restaurar() async {
        isPurchasing = true
        errorMessage = nil
        do {
            try await manager.restorePurchases()
            if manager.isPro { dismiss() }
        } catch {
            errorMessage = error.localizedDescription
        }
        isPurchasing = false
    }

    private func periodLabel(for pkg: Package) -> String? {
        switch pkg.packageType {
        case .monthly: return "/ Month"
        case .annual: return "/ Year"
        default: return nil
        }
    }

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Componentes de Apoio

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("Button"))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct PlanCard: View {
    let title: String
    let price: String
    let period: String?
    let isBestDeal: Bool
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        if isBestDeal {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                Text("Best Deal")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                        }
                    }
                    
                    Text("\(price)\(period ?? "")")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color("ButtonPayOul") : Color(.systemGray4), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color("ButtonPayOul"))
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color("ButtonPayOul").opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color("ButtonPayOul") : Color(.systemGray5), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
