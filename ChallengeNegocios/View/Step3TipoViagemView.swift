//
//  Step3TipoViagemView.swift
//  ChallengeNegocios
//
//  Created by Alana Queiroz on 26/03/26.
//

import SwiftUI
import PostHog

// MARK: - Dados das categorias

private struct CategoriaAtividade {
    let nome: String
    let icone: String
    let itens: [String]
}

private let categorias: [CategoriaAtividade] = [
    CategoriaAtividade(nome: "Nature",  icone: "leaf.circle.fill",       itens: ["Beach", "Hiking", "Camping", "Waterfall", "Cycling", "Mountaineering"]),
    CategoriaAtividade(nome: "Events",  icone: "film",                   itens: ["Shows", "Festivals", "Museums", "Theater", "Exhibitions", "Parks"]),
    CategoriaAtividade(nome: "Sports",  icone: "figure.run.circle.fill", itens: ["Surf", "Diving", "Ski", "Soccer", "Tennis", "Swimming"])
]

// MARK: - Tela 3

struct Step3TipoViagemView: View {
    @Environment(OnboardingViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss
    @State private var abertas: Set<String> = []
    @State private var temSelecao = false

    var body: some View {
        @Bindable var vm = vm

        ZStack {
            // MARK: Background (Mantido o original como você pediu)
            Image("AppFundaTelaPerguntas")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: Linha topo: botão voltar + indicador
                    HStack(alignment: .center) {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 40, height: 40)
                                .foregroundColor(.primary)
                        }
                        .glassEffect(in: Circle())

                        Spacer()

                        StepIndicatorView(etapaAtual: 3, totalEtapas: 4)
                            .frame(maxWidth: 160)

                        Spacer()

                        Color.clear.frame(width: 40, height: 40)
                    }
                    .padding(.bottom, 24)

                    // MARK: Título
                    Text("Trip Type")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.primary)

                    Text("Choose the purpose of your trip.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                        .padding(.bottom, 24)

                    // MARK: Cards Leisure / Business
                    HStack(spacing: 18) {
                        TipoViagemCardView(
                            icone: "sun.horizon.fill",
                            titulo: "Leisure",
                            selecionado: temSelecao && vm.viagem.tipoViagem == .lazer
                        ) {
                            vm.viagem.tipoViagem = .lazer
                            temSelecao = true
                        }

                        TipoViagemCardView(
                            icone: "briefcase.fill",
                            titulo: "Business",
                            selecionado: temSelecao && vm.viagem.tipoViagem == .negocios
                        ) {
                            vm.viagem.tipoViagem = .negocios
                            temSelecao = true
                        }
                    }
                    .padding(.bottom, 32)

                    // MARK: Título Atividades
                    Text("Activities")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.primary)

                    Text("Expand categories and choose what you'd like to do.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                        .padding(.bottom, 16)

                    // MARK: Accordion de categorias
                    VStack(spacing: 12) {
                        ForEach(categorias, id: \.nome) { categoria in
                            CategoriaAccordionView(
                                categoria: categoria,
                                aberta: abertas.contains(categoria.nome),
                                selecionadas: vm.viagem.atividades
                            ) {
                                if abertas.contains(categoria.nome) {
                                    abertas.remove(categoria.nome)
                                } else {
                                    abertas.insert(categoria.nome)
                                }
                            } onToggleItem: { item in
                                if vm.viagem.atividades.contains(item) {
                                    vm.viagem.atividades.removeAll { $0 == item }
                                } else {
                                    vm.viagem.atividades.append(item)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 24)

                    // MARK: Outra atividade
                    Text("Something else?")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .padding(.bottom, 8)

                    TextField(
                        "",
                        text: $vm.viagem.outraAtividade,
                        prompt: Text("E.g. Photography, formal dinner...")
                            .foregroundColor(.secondary),
                        axis: .vertical
                    )
                    .lineLimit(3...5)
                    .foregroundStyle(.primary)
                    .padding(AppLayout.espacamentoInterno)
                    .background(.regularMaterial)
                    .cornerRadius(AppLayout.raioCantos)
                }
                .padding(.horizontal, AppLayout.espacamento)
                .padding(.top, 80)
                .padding(.bottom, AppLayout.alturaBotao + 24)
            }
            .ignoresSafeArea(.keyboard)
            .scrollDismissesKeyboard(.immediately)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                BotaoContinuarView(ativo: temSelecao) {
                    PostHogSDK.shared.capture("onboarding_step3_completed", properties: [
                        "trip_type": vm.viagem.tipoViagem.rawValue,
                        "activities": vm.viagem.atividades,
                        "activities_count": vm.viagem.atividades.count,
                        "has_custom_activity": !vm.viagem.outraAtividade.isEmpty
                    ])
                    vm.avancar(para: 4)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
    }
}

// MARK: - Card Leisure / Business

private struct TipoViagemCardView: View {
    let icone: String
    let titulo: String
    let selecionado: Bool
    let acao: () -> Void

    var body: some View {
        Button(action: acao) {
            ZStack {
                Image(selecionado ? "TipoViagemFundoSelect" : "TipoViagemFundoNormal")
                    .resizable()
                    .scaledToFill()

                VStack(spacing: 10) {
                    Image(systemName: icone)
                        .font(.system(size: 28, weight: .medium))
                    Text(titulo)
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.primary)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .aspectRatio(5/3, contentMode: .fit)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Accordion de categoria

private struct CategoriaAccordionView: View {
    let categoria: CategoriaAtividade
    let aberta: Bool
    let selecionadas: [String]
    let onToggle: () -> Void
    let onToggleItem: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            Button(action: onToggle) {
                HStack(spacing: 12) {
                    Image(systemName: categoria.icone)
                        .font(.title3)
                        .foregroundStyle(Color("Icon"))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(categoria.nome)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        if !aberta {
                            let itensAtivos = categoria.itens.filter { selecionadas.contains($0) }
                            Text(itensAtivos.isEmpty ? "No activities selected yet" : itensAtivos.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Image(systemName: aberta ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(AppLayout.espacamentoInterno)
            }
            .buttonStyle(.plain)

            if aberta {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Selecione as opções:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, AppLayout.espacamentoInterno)

                    ChipsFlowView(
                        itens: categoria.itens,
                        selecionados: selecionadas,
                        onToggle: onToggleItem
                    )
                    .padding(.horizontal, AppLayout.espacamentoInterno)
                    .padding(.bottom, AppLayout.espacamentoInterno)
                }
            }
        }
        .background(.regularMaterial)
        .cornerRadius(AppLayout.raioCantos)
    }
}

// MARK: - Flow de chips

private struct ChipsFlowView: View {
    let itens: [String]
    let selecionados: [String]
    let onToggle: (String) -> Void

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(itens, id: \.self) { item in
                let ativo = selecionados.contains(item)
                Button {
                    onToggle(item)
                } label: {
                    Text(item)
                        .font(.subheadline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(ativo ? Color("RoxoClaro") : Color.primary.opacity(0.10))
                        .foregroundStyle(ativo ? Color.black : Color.primary)
                        .cornerRadius(20)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - FlowLayout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
