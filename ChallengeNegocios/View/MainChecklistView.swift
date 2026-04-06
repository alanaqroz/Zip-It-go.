//
//  MainChecklistView.swift
//  ChallengeNegocios
//
//  Created by Alana Queiroz on 25/03/26.
//

import SwiftUI
import PostHog

struct MainChecklistView: View {
    var vm: ChecklistViewModel

    @State private var mostraAdicionarItem = false
    @State private var categoriaParaAdicionar = ""
    @State private var nomeNovoItem = ""

    private var textoCompartilhavel: String {
        var linhas: [String] = []
        linhas.append("Mala — \(vm.destinoSelecionado)")
        linhas.append(vm.periodoFormatado)
        if !vm.estacao.isEmpty {
            let clima = vm.tempMin != nil
                ? "\(Int(vm.tempMin!))°C - \(Int(vm.tempMax!))°C, \(vm.estacao)"
                : vm.estacao
            linhas.append("Clima: \(clima)")
        }
        linhas.append("")
        for cat in categoriasOrdenadas {
            let itens = itensAgrupados[cat] ?? []
            linhas.append("── \(cat.uppercased()) ──")
            for item in itens {
                let check = item.estaMarcado ? "✓" : "○"
                linhas.append("\(check) \(item.nomeApenas) (\(item.quantidade))")
            }
            linhas.append("")
        }
        return linhas.joined(separator: "\n")
    }

    private let ordemCategorias = [
        "Documents", "Clothing", "Footwear",
        "Toiletries", "Health & Meds", "Electronics",
        "Kids", "Baby"
    ]

    private var itensAgrupados: [String: [ItemMala]] {
        Dictionary(grouping: vm.itens) { $0.categoria }
    }

    private var categoriasOrdenadas: [String] {
        let conhecidas = ordemCategorias.filter { itensAgrupados[$0] != nil }
        let extras = itensAgrupados.keys.filter { !ordemCategorias.contains($0) }.sorted()
        return conhecidas + extras
    }

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            if vm.carregando && vm.itens.isEmpty {
                loadingView
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection
                        if vm.tempMin != nil || !vm.estacao.isEmpty { weatherCard }
                        progressSection
                        ForEach(categoriasOrdenadas, id: \.self) { cat in
                            categorySection(cat, items: itensAgrupados[cat] ?? [])
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ShareLink(
                        item: textoCompartilhavel,
                        preview: SharePreview("Mala — \(vm.destinoSelecionado)")
                    ) {
                        Label("Compartilhar lista", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .fontWeight(.semibold)
                }
            }
        }
        .alert("Adicionar a \(categoriaParaAdicionar)", isPresented: $mostraAdicionarItem) {
            TextField("Nome do item", text: $nomeNovoItem)
            Button("Adicionar") {
                vm.adicionarItem(categoria: categoriaParaAdicionar, nome: nomeNovoItem)
                PostHogSDK.shared.capture("checklist_custom_item_added", properties: [
                    "category": categoriaParaAdicionar,
                    "item": nomeNovoItem
                ])
                nomeNovoItem = ""
            }
            Button("Cancelar", role: .cancel) { nomeNovoItem = "" }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("A analisar destino...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(vm.destinoSelecionado).")
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 5) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(vm.periodoFormatado)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Weather Card

    private var weatherCard: some View {
        HStack(alignment: .center) {
            HStack(spacing: 12) {
                Image(systemName: weatherIcon)
                    .font(.title2)
                    .foregroundColor(weatherIconColor)

                VStack(alignment: .leading, spacing: 3) {
                    if let tMin = vm.tempMin, let tMax = vm.tempMax {
                        HStack(spacing: 6) {
                            Text("\(Int(tMin))°C")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("|")
                                .foregroundColor(.secondary)
                            Text("\(Int(tMax))°C")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                    if !vm.condicaoClima.isEmpty {
                        Text(vm.condicaoClima.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if vm.tempMin == nil {
                        Text("Clima estimado")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if !vm.estacao.isEmpty {
                Text(vm.estacao)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding(16)
        .background(Color.appClimaFundo)
        .cornerRadius(16)
    }

    private var weatherIcon: String {
        guard let tMax = vm.tempMax else { return "cloud.fill" }
        if tMax >= 25 { return "sun.max.fill" }
        if tMax < 15 { return "snowflake" }
        return "cloud.sun.fill"
    }

    private var weatherIconColor: Color {
        guard let tMax = vm.tempMax else { return .gray }
        if tMax >= 25 { return .orange }
        if tMax < 15 { return .blue }
        return .gray
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Packing progress")
                    .font(.subheadline)
                Spacer()
                Text("\(vm.itensMarcados)/\(vm.totalItens) packed")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray4))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.label))
                        .frame(
                            width: vm.totalItens > 0
                                ? geo.size.width * CGFloat(vm.itensMarcados) / CGFloat(vm.totalItens)
                                : 0,
                            height: 6
                        )
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Category Section

    private func categorySection(_ categoria: String, items: [ItemMala]) -> some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack {
                Text(categoria.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(0.5)
                Spacer()
                let marcados = items.filter { $0.estaMarcado }.count
                Text("\(marcados)/\(items.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 6) {
                ForEach(items) { item in
                    itemRow(item)
                }
            }

            Button {
                categoriaParaAdicionar = categoria
                mostraAdicionarItem = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                        .font(.caption)
                    Text("Add to \(categoria)")
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Item Row

    private func itemRow(_ item: ItemMala) -> some View {
        HStack(spacing: 12) {
            // Círculo de marcar
            Button {
                vm.toggleItem(id: item.id)
                PostHogSDK.shared.capture("checklist_item_toggled", properties: [
                    "item": item.nomeApenas,
                    "checked": !item.estaMarcado
                ])
            } label: {
                Image(systemName: item.estaMarcado ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(item.estaMarcado ? .primary : Color(.systemGray3))
            }

            Text(item.nomeApenas)
                .font(.subheadline)
                .strikethrough(item.estaMarcado, color: .secondary)
                .foregroundColor(item.estaMarcado ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Contador — / quantidade / +
            HStack(spacing: 0) {
                Button {
                    vm.ajustarQuantidade(id: item.id, delta: -1)
                    PostHogSDK.shared.capture("checklist_item_quantity_changed", properties: [
                        "item": item.nomeApenas,
                        "delta": -1
                    ])
                } label: {
                    Text("−")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(item.quantidade > 1 ? .primary : Color(.systemGray3))
                        .frame(width: 32, height: 32)
                }
                .disabled(item.quantidade <= 1)

                Divider().frame(height: 16)

                Text("\(item.quantidade)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(minWidth: 28)

                Divider().frame(height: 16)

                Button {
                    vm.ajustarQuantidade(id: item.id, delta: +1)
                    PostHogSDK.shared.capture("checklist_item_quantity_changed", properties: [
                        "item": item.nomeApenas,
                        "delta": 1
                    ])
                } label: {
                    Text("+")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}
