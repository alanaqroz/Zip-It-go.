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
    CategoriaAtividade(nome: "Natureza",  icone: "leaf.circle.fill",       itens: ["Praia", "Trilha", "Camping", "Cachoeira", "Ciclismo", "Montanhismo"]),
    CategoriaAtividade(nome: "Eventos",   icone: "film",                   itens: ["Shows", "Festivais", "Museus", "Teatro", "Exposições", "Parques"]),
    CategoriaAtividade(nome: "Esportes",  icone: "figure.run.circle.fill", itens: ["Surf", "Mergulho", "Ski", "Futebol", "Tênis", "Natação"])
]

// MARK: - Tela 3

struct Step3TipoViagemView: View {
    @Environment(OnboardingViewModel.self) private var vm
    @State private var abertas: Set<String> = []

    var body: some View {
        @Bindable var vm = vm

        ScrollView {
            VStack(alignment: .leading, spacing: AppLayout.espacamento) {

                    StepIndicatorView(etapaAtual: 3, totalEtapas: 4)

                    // Título
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Tipo de viagem")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Escolha qual o propósito da sua viagem")
                            .font(.subheadline)
                            .foregroundColor(.appTextoSecundario)
                    }

                    // Cards Lazer / Negócios
                    HStack(spacing: 12) {
                        TipoViagemCardView(
                            icone: "sun.horizon.fill",
                            titulo: "Lazer",
                            selecionado: vm.viagem.tipoViagem == .lazer
                        ) { vm.viagem.tipoViagem = .lazer }

                        TipoViagemCardView(
                            icone: "briefcase.fill",
                            titulo: "Negócios",
                            selecionado: vm.viagem.tipoViagem == .negocios
                        ) { vm.viagem.tipoViagem = .negocios }
                    }

                    // Atividades
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Atividades")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Expanda as categorias e escolha o que deseja fazer.")
                            .font(.subheadline)
                            .foregroundColor(.appTextoSecundario)
                    }

                    // Accordion de categorias
                    VStack(spacing: 12) {
                        ForEach(categorias, id: \.nome) { categoria in
                            CategoriaAccordionView(
                                categoria: categoria,
                                aberta: abertas.contains(categoria.nome),
                                selecionadas: vm.viagem.atividades
                            ) {
                                // Abre / fecha
                                if abertas.contains(categoria.nome) {
                                    abertas.remove(categoria.nome)
                                } else {
                                    abertas.insert(categoria.nome)
                                }
                            } onToggleItem: { item in
                                // Seleciona / deseleciona chip
                                if vm.viagem.atividades.contains(item) {
                                    vm.viagem.atividades.removeAll { $0 == item }
                                } else {
                                    vm.viagem.atividades.append(item)
                                }
                            }
                        }
                    }

                    // Outra atividade
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Outra atividade?")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        TextField("Ex. Fotografia, jantar formal...", text: $vm.viagem.outraAtividade, axis: .vertical)
                            .lineLimit(3...5)
                            .padding(AppLayout.espacamentoInterno)
                            .background(Color.appFundoSecundario)
                            .cornerRadius(AppLayout.raioCantos)
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, AppLayout.espacamento)
                .padding(.top, AppLayout.espacamento)
        }
        .scrollDismissesKeyboard(.immediately)
        .onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
        .safeAreaInset(edge: .bottom) {
            BotaoContinuarView(ativo: true) {
                PostHogSDK.shared.capture("onboarding_step3_completed", properties: [
                    "trip_type": vm.viagem.tipoViagem.rawValue,
                    "activities": vm.viagem.atividades,
                    "activities_count": vm.viagem.atividades.count,
                    "has_custom_activity": !vm.viagem.outraAtividade.isEmpty
                ])
                vm.avancar(para: 4)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Card Lazer / Negócios

private struct TipoViagemCardView: View {
    let icone: String
    let titulo: String
    let selecionado: Bool
    let acao: () -> Void

    var body: some View {
        Button(action: acao) {
            VStack(spacing: 10) {
                Image(systemName: icone)
                    .font(.title2)
                    .foregroundColor(selecionado ? .primary : .appTextoSecundario)
                Text(titulo)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(selecionado ? .primary : .appTextoSecundario)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(selecionado ? Color(.systemGray4) : Color.appFundoSecundario)
            .cornerRadius(AppLayout.raioCantos)
        }
    }
}

// MARK: - Accordion de categoria

private struct CategoriaAccordionView: View {
    let categoria: CategoriaAtividade
    let aberta: Bool
    let selecionadas: [String]
    let onToggle: () -> Void
    let onToggleItem: (String) -> Void

    private var resumo: String {
        let itensAtivos = categoria.itens.filter { selecionadas.contains($0) }
        return itensAtivos.isEmpty ? "Nenhuma atividade selecionada" : itensAtivos.joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // toca pra abrir/fechar
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    Image(systemName: categoria.icone)
                        .font(.title3)
                        .foregroundColor(.primary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(categoria.nome)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        if !aberta {
                            Text(resumo)
                                .font(.caption)
                                .foregroundColor(.appTextoSecundario)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Image(systemName: aberta ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.appTextoSecundario)
                }
                .padding(AppLayout.espacamentoInterno)
            }
            .buttonStyle(.plain)

            // Chips — visíveis só quando aberto
            if aberta {
                ChipsFlowView(
                    itens: categoria.itens,
                    selecionados: selecionadas,
                    onToggle: onToggleItem
                )
                .padding(.horizontal, AppLayout.espacamentoInterno)
                .padding(.bottom, AppLayout.espacamentoInterno)
            }
        }
        .background(Color.appFundoSecundario)
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
                Button {
                    onToggle(item)
                } label: {
                    Text(item)
                        .font(.subheadline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selecionados.contains(item) ? Color(.systemGray3) : Color(.systemGray5))
                        .foregroundColor(.primary)
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
