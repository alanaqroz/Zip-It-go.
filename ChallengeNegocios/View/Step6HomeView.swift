//
//  Step6HomeView.swift
//  ChallengeNegocios
//
//  Created by Alana Queiroz on 26/03/26.
//

import SwiftUI

struct Step6HomeView: View {
    @Environment(ViagemStore.self) private var store
    @Binding var mostraOnboarding: Bool
    @State private var busca = ""
    @State private var showPaywall = false
    @State private var showSubscription = false
    @State private var manager = SubscriptionManager.shared

    private var hoje: Date { Calendar.current.startOfDay(for: Date()) }

    private var proximaViagem: Viagem? {
        store.viagens
            .filter { Calendar.current.startOfDay(for: $0.dataIda) >= hoje }
            .sorted { $0.dataIda < $1.dataIda }
            .first
    }

    private var diasAteProxima: Int {
        guard let proxima = proximaViagem else { return 0 }
        return Calendar.current.dateComponents(
            [.day], from: hoje,
            to: Calendar.current.startOfDay(for: proxima.dataIda)
        ).day ?? 0
    }

    private var viagensFiltradas: [Viagem] {
        busca.isEmpty
            ? store.viagens
            : store.viagens.filter { $0.destino.localizedCaseInsensitiveContains(busca) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.viagens.isEmpty {
                    estadoVazio
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 28) {

                            // Saudação
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Text("Hi")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                    if manager.isPro { ProBadge() }
                                    Spacer()
                                    Button {
                                        showSubscription = true
                                    } label: {
                                        Image(systemName: manager.isPro ? "person.crop.circle.fill.badge.checkmark" : "person.crop.circle")
                                            .font(.title2)
                                            .foregroundStyle(manager.isPro ? .purple : .secondary)
                                    }
                                }

                                if proximaViagem != nil {
                                    Text("Sua próxima viagem é em **\(diasAteProxima) dias**. Pronta para montar a mala?")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Nenhuma viagem próxima.\nQue tal criar uma nova?")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }

                                if !manager.isPro {
                                    UpgradeButton(showPaywall: $showPaywall)
                                        .padding(.top, 4)
                                }
                            }

                            // Próxima viagem
                            if let proxima = proximaViagem {
                                SecaoHomeView(titulo: "Next Trip") {
                                    NavigationLink {
                                        ViagemDetalheView(viagem: proxima)
                                    } label: {
                                        CardViagemView(viagem: proxima)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            // Todas as viagens
                            SecaoHomeView(titulo: "All Trips") {
                                ForEach(viagensFiltradas) { viagem in
                                    NavigationLink {
                                        ViagemDetalheView(viagem: viagem)
                                    } label: {
                                        CardViagemView(viagem: viagem)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, AppLayout.espacamento)
                        .padding(.top, AppLayout.espacamento)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            barraInferior
        }
        // ── Paywall sheet ──────────────────────────────────────────────────
        .paywallSheet(isPresented: $showPaywall)
        // ── Subscription management ────────────────────────────────────────
        .sheet(isPresented: $showSubscription) {
            NavigationStack {
                SubscriptionStatusView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showSubscription = false }
                        }
                    }
            }
        }
    }

    // MARK: - Barra inferior

    private var barraInferior: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search", text: $busca)
                if !busca.isEmpty {
                    Button { busca = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                } else {
                    Image(systemName: "mic.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.systemGray5))
            .cornerRadius(24)

            Button {
                mostraOnboarding = true
            } label: {
                Image(systemName: "plus")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .frame(width: 48, height: 48)
                    .background(Color(.systemGray5))
                    .cornerRadius(24)
            }
        }
        .padding(.horizontal, AppLayout.espacamento)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    // MARK: - Estado vazio

    private var estadoVazio: some View {
        VStack(spacing: 16) {
            Image(systemName: "suitcase")
                .font(.system(size: 52))
                .foregroundColor(Color(.systemGray3))
            Text("Nenhuma viagem ainda")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Toque em \"+\" para começar\na montar sua mala.")
                .font(.subheadline)
                .foregroundColor(.appTextoSecundario)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Seção com título + linha

private struct SecaoHomeView<Conteudo: View>: View {
    let titulo: String
    @ViewBuilder let conteudo: () -> Conteudo

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Text(titulo)
                    .font(.title3)
                    .fontWeight(.semibold)
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(height: 1)
            }
            conteudo()
        }
    }
}

// MARK: - Card de viagem

private struct CardViagemView: View {
    let viagem: Viagem

    private var diasAtePartida: Int {
        let hoje = Calendar.current.startOfDay(for: Date())
        let partida = Calendar.current.startOfDay(for: viagem.dataIda)
        return max(0, Calendar.current.dateComponents([.day], from: hoje, to: partida).day ?? 0)
    }

    private var periodoResumido: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM"
        fmt.locale = Locale(identifier: "pt_BR")
        return "\(fmt.string(from: viagem.dataIda)) - \(fmt.string(from: viagem.dataVolta))"
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {

                // Nome + badge tipo
                HStack(spacing: 8) {
                    Text(viagem.destino)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text(viagem.tipoViagem.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }

                // Dias até a partida
                Text("in \(diasAtePartida) days")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Período + temperatura
                HStack(spacing: 10) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(periodoResumido)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)

                    if let tMax = viagem.tempMax {
                        HStack(spacing: 4) {
                            Image(systemName: "thermometer.medium")
                                .font(.caption)
                            Text("\(Int(tMax))°")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }

                // Total de itens
                HStack(spacing: 4) {
                    Image(systemName: "suitcase.fill")
                        .font(.caption)
                    Text("\(viagem.itens.count) itens")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline)
                .foregroundColor(Color(.systemGray3))
        }
        .padding(AppLayout.espacamentoInterno)
        .background(Color(.systemGray6))
        .cornerRadius(AppLayout.raioCantos)
    }
}

// MARK: - Detalhe de viagem salva

struct ViagemDetalheView: View {
    let viagem: Viagem
    @State private var checklistVM = ChecklistViewModel()

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            MainChecklistView(vm: checklistVM)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checklistVM.configurar(com: viagem)
            checklistVM.itens         = viagem.itens
            checklistVM.tempMin       = viagem.tempMin
            checklistVM.tempMax       = viagem.tempMax
            checklistVM.condicaoClima = viagem.condicaoClima
            checklistVM.estacao       = viagem.estacao
        }
    }
}
