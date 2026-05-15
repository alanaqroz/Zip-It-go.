//
//  MainChecklistView.swift
//  ChallengeNegocios
//
//  Created by Alana Queiroz on 25/03/26.
//

import SwiftUI
import PostHog

// MARK: - Share sheet wrapper
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}

// MARK: - PDF Export helper
private func gerarPDF(vm: ChecklistViewModel,
                      categoriasOrdenadas: [String],
                      itensAgrupados: [String: [ItemMala]]) -> URL? {

    let pageWidth: CGFloat  = 595   // A4 largura em pontos
    let margin:    CGFloat  = 36
    let contentW:  CGFloat  = pageWidth - margin * 2

    // ── Cores ───────────────────────────────────────────────────
    let corFundo    = UIColor(red: 0.06, green: 0.04, blue: 0.18, alpha: 1)
    let corAccent   = UIColor(red: 0.71, green: 0.95, blue: 0.24, alpha: 1)
    let corBranco   = UIColor.white
    let corCinza    = UIColor(white: 1, alpha: 0.55)
    let corCard     = UIColor(white: 1, alpha: 0.07)

    // ── Fonte helpers ────────────────────────────────────────────
    func bold(_ size: CGFloat)    -> UIFont { .systemFont(ofSize: size, weight: .bold) }
    func regular(_ size: CGFloat) -> UIFont { .systemFont(ofSize: size, weight: .regular) }
    func heavy(_ size: CGFloat)   -> UIFont { .systemFont(ofSize: size, weight: .heavy) }

    // ── Calcular altura total necessária ─────────────────────────
    var totalH: CGFloat = margin + 80 + 16 + 24 + 16 + 24 + 20 + 32   // header fixo

    for cat in categoriasOrdenadas {
        let itens = itensAgrupados[cat] ?? []
        totalH += 32   // cabeçalho categoria
        totalH += CGFloat(itens.count) * 40   // itens
        totalH += 16   // espaço após categoria
    }
    totalH += margin

    // ── Criar PDF ───────────────────────────────────────────────
    let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: totalH)
    let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

    let tempURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("ZipIt_PackingList.pdf")

    do {
        try renderer.writePDF(to: tempURL) { ctx in
            ctx.beginPage()
            let cgCtx = ctx.cgContext

            // Fundo
            cgCtx.setFillColor(corFundo.cgColor)
            cgCtx.fill(pageRect)

            var y: CGFloat = margin

            // ── Título ──────────────────────────────────────────
            let titulo = "Zip It! — Packing List"
            let atTitulo: [NSAttributedString.Key: Any] = [
                .font: heavy(22), .foregroundColor: corBranco
            ]
            titulo.draw(at: CGPoint(x: margin, y: y), withAttributes: atTitulo)
            y += 30

            // Destino
            let destino = vm.destinoSelecionado
            let atDestino: [NSAttributedString.Key: Any] = [
                .font: bold(15), .foregroundColor: corAccent
            ]
            destino.draw(at: CGPoint(x: margin, y: y), withAttributes: atDestino)
            y += 22

            // Período
            let periodo = vm.periodoFormatado
            let atPeriodo: [NSAttributedString.Key: Any] = [
                .font: regular(12), .foregroundColor: corCinza
            ]
            periodo.draw(at: CGPoint(x: margin, y: y), withAttributes: atPeriodo)
            y += 18

            // Clima
            if !vm.estacao.isEmpty {
                let clima: String
                if let tMin = vm.tempMin, let tMax = vm.tempMax {
                    clima = "🌤 \(Int(tMin))°C – \(Int(tMax))°C · \(vm.estacao)"
                } else {
                    clima = "🌤 \(vm.estacao)"
                }
                clima.draw(at: CGPoint(x: margin, y: y), withAttributes: atPeriodo)
                y += 18
            }

            // Progresso
            let totalItens  = itensAgrupados.values.flatMap { $0 }.count
            let marcados    = itensAgrupados.values.flatMap { $0 }.filter { $0.estaMarcado }.count
            let progresso   = "✓ \(marcados) of \(totalItens) items packed"
            progresso.draw(at: CGPoint(x: margin, y: y), withAttributes: atPeriodo)
            y += 24

            // Linha separadora
            cgCtx.setStrokeColor(UIColor(white: 1, alpha: 0.15).cgColor)
            cgCtx.setLineWidth(0.5)
            cgCtx.move(to: CGPoint(x: margin, y: y))
            cgCtx.addLine(to: CGPoint(x: pageWidth - margin, y: y))
            cgCtx.strokePath()
            y += 20

            // ── Categorias ──────────────────────────────────────
            for cat in categoriasOrdenadas {
                let itens = itensAgrupados[cat] ?? []

                // Cabeçalho da categoria
                let marcadosCat = itens.filter { $0.estaMarcado }.count
                let labelCat = "\(cat.uppercased())  \(marcadosCat)/\(itens.count)"
                let atCat: [NSAttributedString.Key: Any] = [
                    .font: bold(11),
                    .foregroundColor: corAccent,
                    .kern: 1.2
                ]
                labelCat.draw(at: CGPoint(x: margin, y: y), withAttributes: atCat)
                y += 22

                // Itens
                for item in itens {
                    // Card de fundo
                    let cardRect = CGRect(x: margin, y: y, width: contentW, height: 32)
                    cgCtx.setFillColor(corCard.cgColor)
                    let path = UIBezierPath(roundedRect: cardRect, cornerRadius: 8)
                    cgCtx.addPath(path.cgPath)
                    cgCtx.fillPath()

                    // Checkbox
                    let boxSize: CGFloat = 14
                    let boxRect = CGRect(x: margin + 10, y: y + 9, width: boxSize, height: boxSize)
                    if item.estaMarcado {
                        cgCtx.setFillColor(corAccent.cgColor)
                        let boxPath = UIBezierPath(roundedRect: boxRect, cornerRadius: 3)
                        cgCtx.addPath(boxPath.cgPath)
                        cgCtx.fillPath()
                        // Check mark
                        let atCheck: [NSAttributedString.Key: Any] = [
                            .font: bold(9), .foregroundColor: UIColor.black
                        ]
                        "✓".draw(at: CGPoint(x: margin + 12, y: y + 10), withAttributes: atCheck)
                    } else {
                        cgCtx.setStrokeColor(UIColor(white: 1, alpha: 0.3).cgColor)
                        cgCtx.setLineWidth(1)
                        let boxPath = UIBezierPath(roundedRect: boxRect, cornerRadius: 3)
                        cgCtx.addPath(boxPath.cgPath)
                        cgCtx.strokePath()
                    }

                    // Nome do item
                    let atItem: [NSAttributedString.Key: Any] = [
                        .font: regular(12),
                        .foregroundColor: item.estaMarcado ? corCinza : corBranco
                    ]
                    item.nomeApenas.draw(at: CGPoint(x: margin + 34, y: y + 10), withAttributes: atItem)

                    // Quantidade
                    let qty = "×\(item.quantidade)"
                    let atQty: [NSAttributedString.Key: Any] = [
                        .font: regular(11), .foregroundColor: corCinza
                    ]
                    let qtyW = (qty as NSString).size(withAttributes: atQty).width
                    qty.draw(at: CGPoint(x: pageWidth - margin - qtyW - 10, y: y + 11),
                             withAttributes: atQty)

                    y += 40
                }

                y += 16   // espaço após categoria
            }

            // ── Rodapé ──────────────────────────────────────────
            let rodape = "Generated by Zip It!"
            let atRodape: [NSAttributedString.Key: Any] = [
                .font: regular(9), .foregroundColor: corCinza
            ]
            let rodapeW = (rodape as NSString).size(withAttributes: atRodape).width
            rodape.draw(at: CGPoint(x: (pageWidth - rodapeW) / 2, y: y + 8),
                        withAttributes: atRodape)
        }
        return tempURL
    } catch {
        print("Erro ao gerar PDF: \(error)")
        return nil
    }
}

struct MainChecklistView: View {
    var vm: ChecklistViewModel
    var onVoltar: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var mostraAdicionarItem = false
    @State private var categoriaParaAdicionar = ""
    @State private var nomeNovoItem = ""
    @State private var buscaAtiva = false
    @State private var textoBusca = ""
    @State private var urlPDFExportado: URL? = nil
    @State private var mostraShareSheet = false

    // MARK: - Export text

    private var textoCompartilhavel: String {
        var linhas: [String] = []
        linhas.append("Packing List — \(vm.destinoSelecionado)")
        linhas.append(vm.periodoFormatado)
        if !vm.estacao.isEmpty {
            let clima = vm.tempMin != nil
                ? "\(Int(vm.tempMin!))°C - \(Int(vm.tempMax!))°C, \(vm.estacao)"
                : vm.estacao
            linhas.append("Weather: \(clima)")
        }
        linhas.append("")
        for cat in categoriasOrdenadas {
            let itens = itensAgrupados[cat] ?? []
            linhas.append("── \(cat.uppercased()) ──")
            for item in itens {
                let check = item.estaMarcado ? "✓" : "○"
                linhas.append("\(check) \(item.nomeApenas) (x\(item.quantidade))")
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
        let fonte = textoBusca.isEmpty ? vm.itens : vm.itens.filter {
            $0.nomeApenas.localizedCaseInsensitiveContains(textoBusca)
        }
        return Dictionary(grouping: fonte) { $0.categoria }
    }

    private var categoriasOrdenadas: [String] {
        let conhecidas = ordemCategorias.filter { itensAgrupados[$0] != nil }
        let extras = itensAgrupados.keys.filter { !ordemCategorias.contains($0) }.sorted()
        return conhecidas + extras
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Image("FundoLista")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            List {
                // MARK: Header (title + weather + progress)
                Section {
                    titleWeatherProgress
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 0, trailing: 0))
                }

                // MARK: Categories
                ForEach(categoriasOrdenadas, id: \.self) { cat in
                    Section {
                        ForEach(itensAgrupados[cat] ?? []) { item in
                            itemRow(item)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 24, bottom: 4, trailing: 24))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        vm.removerItem(id: item.id)
                                        PostHogSDK.shared.capture("checklist_item_deleted", properties: [
                                            "item": item.nomeApenas
                                        ])
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }

                        // Add item button
                        Button {
                            categoriaParaAdicionar = cat
                            mostraAdicionarItem = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.body.weight(.semibold))
                                Text("Add item to \(cat)")
                                    .font(.body)
                            }
                            .foregroundStyle(Color("Button"))
                            .padding(.top, 4)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 24, bottom: 12, trailing: 24))

                    } header: {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(cat)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            let marcados = (itensAgrupados[cat] ?? []).filter { $0.estaMarcado }.count
                            let total = (itensAgrupados[cat] ?? []).count
                            Text("\(marcados)/\(total)")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .textCase(nil)
                        .padding(.bottom, 6)
                        .padding(.horizontal, 24)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .safeAreaInset(edge: .top, spacing: 0) {
                navRow
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $mostraShareSheet) {
            if let url = urlPDFExportado {
                ShareSheet(items: [url])
            }
        }
        .alert("Add to \(categoriaParaAdicionar)", isPresented: $mostraAdicionarItem) {
            TextField("Item name", text: $nomeNovoItem)
            Button("Add") {
                vm.adicionarItem(categoria: categoriaParaAdicionar, nome: nomeNovoItem)
                PostHogSDK.shared.capture("checklist_custom_item_added", properties: [
                    "category": categoriaParaAdicionar,
                    "item": nomeNovoItem
                ])
                nomeNovoItem = ""
            }
            Button("Cancel", role: .cancel) { nomeNovoItem = "" }
        }
    }

    // MARK: - Nav row

    private var navRow: some View {
        VStack(spacing: 10) {
            // Linha de botões
            HStack {
                Button {
                    if let onVoltar { onVoltar() } else { dismiss() }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 40, height: 40)
                }
                .glassEffect(in: Circle())

                Spacer()

                HStack(spacing: 0) {
                    // Lupa — abre/fecha barra de busca no topo
                    Button {
                        withAnimation(.spring(duration: 0.3)) { buscaAtiva.toggle() }
                        if !buscaAtiva { textoBusca = "" }
                    } label: {
                        Image(systemName: buscaAtiva ? "xmark" : "magnifyingglass")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 46, height: 40)
                    }

                    // Exportar — gera PDF com a lista completa
                    Button {
                        DispatchQueue.main.async {
                            urlPDFExportado = gerarPDF(
                                vm: vm,
                                categoriasOrdenadas: categoriasOrdenadas,
                                itensAgrupados: itensAgrupados
                            )
                            mostraShareSheet = urlPDFExportado != nil
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 46, height: 40)
                    }
                }
                .glassEffect(in: Capsule())
            }

            // Barra de busca — aparece abaixo dos botões com glass
            if buscaAtiva {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search items...", text: $textoBusca)
                        .foregroundColor(.primary)
                        .autocorrectionDisabled()
                    if !textoBusca.isEmpty {
                        Button { textoBusca = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .glassEffect(in: Capsule())
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 70)
        .padding(.top, UIDevice.current.userInterfaceIdiom == .pad ? 10 : 0)
        .padding(.bottom, 8)
    }

    // MARK: - Title + weather + progress

    private var titleWeatherProgress: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 6) {
                Text("\(vm.destinoSelecionado).")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(vm.periodoFormatado)
                        .font(.body)
                }
                .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 20)

            // Weather card + WeatherKit attribution
            if vm.tempMin != nil || !vm.estacao.isEmpty {
                VStack(alignment: .trailing, spacing: 6) {
                    weatherCard

                    // Atribuição obrigatória do WeatherKit (Apple guideline)
                    Link(destination: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!) {
                        HStack(spacing: 4) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 10, weight: .medium))
                            Text("Weather")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 20)
            }

            // Progress
            progressSection.padding(.bottom, 8)
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Weather Card

    private var weatherCard: some View {
        ZStack {
            Image("CardClima")
                .resizable()
                .scaledToFill()

            HStack(alignment: .center) {
                HStack(spacing: 12) {
                    Image(systemName: weatherIcon)
                        .font(.title2)
                        .foregroundStyle(.primary)

                    VStack(alignment: .leading, spacing: 4) {
                        if let tMin = vm.tempMin, let tMax = vm.tempMax {
                            HStack(spacing: 6) {
                                Text("\(Int(tMin))°C")
                                    .font(.system(size: 20, weight: .bold))
                                Text("|")
                                    .foregroundStyle(.secondary)
                                Text("\(Int(tMax))°C")
                                    .font(.system(size: 20, weight: .bold))
                            }
                            .foregroundStyle(.primary)
                        }
                        if !vm.condicaoClima.isEmpty {
                            Text(vm.condicaoClima.capitalized)
                                .font(.body)
                                .foregroundStyle(.primary.opacity(0.85))
                        }
                    }
                }

                Spacer()

                if !vm.estacao.isEmpty {
                    Text(vm.estacao)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                }
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .frame(height: 90)
    }

    private var weatherIcon: String {
        let c = vm.condicaoClima.lowercased()
        if c.contains("thunder") || c.contains("storm")               { return "cloud.bolt.rain.fill" }
        if c.contains("snow") || c.contains("blizzard") || c.contains("sleet") || c.contains("flurr") { return "cloud.snow.fill" }
        if c.contains("rain") || c.contains("drizzle") || c.contains("shower") { return "cloud.drizzle.fill" }
        if c.contains("cloud") || c.contains("overcast") || c.contains("fog") || c.contains("haz") { return "smoke.fill" }
        if c.contains("clear") || c.contains("sun") || c.contains("hot") { return "sun.max.fill" }
        // fallback por temperatura
        guard let tMax = vm.tempMax else { return "cloud.fill" }
        if tMax >= 25 { return "sun.max.fill" }
        if tMax < 5  { return "cloud.snow.fill" }
        return "cloud.sun.fill"
    }

    // MARK: - Progress

    private var progressSection: some View {
            VStack(spacing: 10) {
                HStack {
                    Text("PACKING PROGRESS:")
                        .font(.caption.weight(.bold))
                        .tracking(0.6)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(vm.itensMarcados)/\(vm.totalItens) packed")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.primary.opacity(0.12))
                            .frame(width: geo.size.width, height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color("Button"))
                            .frame(
                                width: vm.totalItens > 0
                                    ? geo.size.width * CGFloat(vm.itensMarcados) / CGFloat(vm.totalItens)
                                    : 0,
                                height: 6
                            )
                            .animation(.spring(response: 0.4), value: vm.itensMarcados)
                    }
                }
                .frame(height: 6)
            }
        }

    // MARK: - Item Row

    private func itemRow(_ item: ItemMala) -> some View {
            HStack(spacing: 14) {
                // Checkbox
                Button {
                    vm.toggleItem(id: item.id)
                    PostHogSDK.shared.capture("checklist_item_toggled", properties: [
                        "item": item.nomeApenas,
                        "checked": !item.estaMarcado
                    ])
                } label: {
                    ZStack {
                        Circle()
                            .strokeBorder(
                                item.estaMarcado ? Color.clear : Color.primary.opacity(0.35),
                                lineWidth: 1.5
                            )
                            .background(
                                Circle().fill(item.estaMarcado ? Color("Button") : Color.clear)
                            )
                            .frame(width: 26, height: 26)

                        if item.estaMarcado {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color("ButtonLabel"))
                        }
                    }
                }
                .buttonStyle(.plain)

                Text(item.nomeApenas)
                    .font(.body)
                    .strikethrough(item.estaMarcado, color: .secondary)
                    .foregroundColor(item.estaMarcado ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Quantity
                if item.estaMarcado {
                    Text("\(item.quantidade)")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.secondary)
                        .frame(minWidth: 28, alignment: .center)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.primary.opacity(0.08))
                        .cornerRadius(12) 
                } else {
                    HStack(spacing: 0) {
                        Button {
                            vm.ajustarQuantidade(id: item.id, delta: -1)
                            PostHogSDK.shared.capture("checklist_item_quantity_changed", properties: [
                                "item": item.nomeApenas, "delta": -1
                            ])
                        } label: {
                            Text("−")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(item.quantidade > 1 ? .primary : Color.primary.opacity(0.3))
                                .frame(width: 32, height: 36)
                        }
                        .disabled(item.quantidade <= 1)
                        .buttonStyle(.plain)

                        Text("\(item.quantidade)")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.primary)
                            .frame(minWidth: 28, alignment: .center)

                        Button {
                            vm.ajustarQuantidade(id: item.id, delta: +1)
                            PostHogSDK.shared.capture("checklist_item_quantity_changed", properties: [
                                "item": item.nomeApenas, "delta": +1
                            ])
                        } label: {
                            Text("+")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(width: 32, height: 36)
                        }
                        .buttonStyle(.plain)
                    }
                    .background(Color.primary.opacity(0.10))
                    .cornerRadius(24)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(24)         }
}
