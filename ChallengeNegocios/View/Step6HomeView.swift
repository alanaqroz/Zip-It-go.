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
            ZStack(alignment: .bottomTrailing) {
                List {
                    Section {
                        topoHeader
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    if store.viagens.isEmpty {
                        Section {
                            estadoVazio
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        // Upcoming Trip
                        if let proxima = proximaViagem {
                            Section(header: secaoHeader("Upcoming Trip")) {
                                ZStack {
                                    NavigationLink {
                                        ViagemDetalheView(viagem: proxima)
                                    } label: { EmptyView() }
                                        .opacity(0)
                                    CardViagemView(viagem: proxima)
                                }
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        store.remover(id: proxima.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }

                        // All Trips
                        Section(header: secaoHeader("All Trips")) {
                            ForEach(viagensFiltradas) { viagem in
                                ZStack {
                                    NavigationLink {
                                        ViagemDetalheView(viagem: viagem)
                                    } label: { EmptyView() }
                                        .opacity(0)
                                    CardViagemView(viagem: viagem)
                                }
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        store.remover(id: viagem.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }

                    // Espaço para o botão flutuante
                    Section { Color.clear.frame(height: 80) }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .ignoresSafeArea(edges: .top)

                //  Botão "+" flutuante
                Button {
                    // 1 lista grátis — a partir da 2ª exige Pro
                    if store.viagens.isEmpty || manager.isPro {
                        mostraOnboarding = true
                    } else {
                        showPaywall = true
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.secondary)
                        .frame(width: 56, height: 56)
                }
                .glassEffect(in: Circle())
                .padding(.trailing, 20)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showPaywall) {
            CustomPaywallView()
        }
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

    // MARK: - Topo Header

    private var topoHeader: some View {
        ZStack(alignment: .bottomLeading) {
            Image("Topo")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .clipped()

            VStack(alignment: .leading, spacing: 12) {
                Spacer()

                // Título
                Text("Welcome!")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.primary)

                // Subtítulo
                if proximaViagem != nil {
                    Text("Your next trip is in ")
                        .font(.body)
                        .foregroundStyle(.primary)
                    + Text("\(diasAteProxima) days")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("Button"))
                    + Text(". Ready to check your packing list?")
                        .font(.body)
                        .foregroundStyle(.primary)
                } else {
                    Text("No upcoming trips yet. Ready to plan one?")
                        .font(.body)
                        .foregroundStyle(.primary)
                }

                // Barra de busca — Liquid Glass
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search", text: $busca)
                        .foregroundStyle(.primary)
                    Spacer()
                    if !busca.isEmpty {
                        Button { busca = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .glassEffect(in: Capsule())
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Header de seção

    private func secaoHeader(_ titulo: String) -> some View {
        HStack(spacing: 12) {
            Text(titulo)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .textCase(nil)
        .listRowInsets(EdgeInsets())
        .background(Color(.systemBackground))
    }

    // MARK: - Estado vazio

    private var estadoVazio: some View {
        VStack(spacing: 16) {
            Image(systemName: "suitcase")
                .font(.system(size: 52))
                .foregroundStyle(Color(.systemGray3))
            Text("No trips yet")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Tap \"+\" to start\npacking your bag.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Card de viagem

private struct CardViagemView: View {
    let viagem: Viagem

    private var periodoResumido: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM"
        fmt.locale = Locale(identifier: "en_US")
        return "\(fmt.string(from: viagem.dataIda)) – \(fmt.string(from: viagem.dataVolta))"
    }

    // Cores do tag por tipo de viagem
    private var tagBackground: Color {
        viagem.tipoViagem == .negocios
            ? Color(.systemIndigo)
            : Color("Button")
    }
    private var tagForeground: Color {
        viagem.tipoViagem == .negocios
            ? .white
            : Color("ButtonLabel")
    }

    // Ícone de clima baseado na condição textual
    private var weatherIcon: String {
        let c = viagem.condicaoClima.lowercased()
        if c.contains("thunder") || c.contains("storm")                                     { return "cloud.bolt.rain.fill" }
        if c.contains("snow") || c.contains("blizzard") || c.contains("sleet") || c.contains("flurr") { return "cloud.snow.fill" }
        if c.contains("rain") || c.contains("drizzle") || c.contains("shower")             { return "cloud.drizzle.fill" }
        if c.contains("cloud") || c.contains("fog") || c.contains("haz") || c.contains("overcast") { return "smoke.fill" }
        if c.contains("clear") || c.contains("sun") || c.contains("hot")                   { return "sun.max.fill" }
        // fallback por temperatura
        guard let tMax = viagem.tempMax else { return "thermometer.medium" }
        if tMax >= 25 { return "sun.max.fill" }
        if tMax < 5  { return "cloud.snow.fill" }
        return "cloud.sun.fill"
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {

                // Tag no topo
                Text(viagem.tipoViagem.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(tagForeground)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(tagBackground)
                    .clipShape(Capsule())

                // Nome do destino
                Text(viagem.destino)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                // Período + temperatura com ícone dinâmico
                HStack(spacing: 12) {
                    HStack(spacing: 5) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(periodoResumido)
                            .font(.body)
                    }
                    .foregroundStyle(.secondary)

                    if let tMax = viagem.tempMax {
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(width: 1, height: 14)

                        HStack(spacing: 4) {
                            Image(systemName: weatherIcon)
                                .font(.caption)
                            Text("\(Int(tMax))° C")
                                .font(.body)
                        }
                        .foregroundStyle(.secondary)
                    }
                }

                // Total de itens
                HStack(spacing: 5) {
                    Image(systemName: "bag.fill")
                        .font(.caption)
                    Text("\(viagem.itens.count) items")
                        .font(.body)
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Detalhe de viagem salva

struct ViagemDetalheView: View {
    let viagem: Viagem
    @State private var checklistVM = ChecklistViewModel()
    @Environment(ViagemStore.self) private var store

    var body: some View {
        MainChecklistView(vm: checklistVM)
            .navigationBarHidden(true)
            .onAppear {
                checklistVM.configurar(com: viagem)
                checklistVM.itens         = viagem.itens
                checklistVM.tempMin       = viagem.tempMin
                checklistVM.tempMax       = viagem.tempMax
                checklistVM.condicaoClima = viagem.condicaoClima
                checklistVM.estacao       = viagem.estacao
            }
            // Sincroniza qualquer alteração no checklist (marcar item, mudar
            // quantidade, adicionar/remover) de volta na ViagemStore. Sem isso,
            // as mudanças ficavam só na memória do ViewModel e sumiam ao sair
            // e reabrir a viagem.
            .onChange(of: checklistVM.itens) { _, novosItens in
                var viagemAtualizada = viagem
                viagemAtualizada.itens = novosItens
                store.atualizar(viagemAtualizada)
            }
    }
}
