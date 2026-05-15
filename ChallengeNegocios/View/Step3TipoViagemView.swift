//
//  Step3TipoViagemView.swift
//  ChallengeNegocios
//
//  Created by Alana Queiroz on 26/03/26.
//

internal import Combine
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
    CategoriaAtividade(nome: "Events",  icone: "ticket.fill",                  itens: ["Shows", "Festivals", "Museums", "Theater", "Exhibitions", "Parks"]),
    CategoriaAtividade(nome: "Sports",  icone: "figure.run.circle.fill", itens: ["Surf", "Diving", "Ski", "Soccer", "Tennis", "Swimming, Sport"])
]

// MARK: - Tela 3
struct Step3TipoViagemView: View {
    @Environment(OnboardingViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss
    
    @State private var abertas: Set<String> = []
    @State private var temSelecao = false
    
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        @Bindable var vm = vm

        ZStack(alignment: .bottom) {
            Image("AppFundaTelaPerguntas")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

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
                        .font(.body)
                        .foregroundStyle(.primary)
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

                    Text("Activities")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.primary)

                    Text("Expand categories and choose what you'd like to do.")
                        .font(.body)
                        .foregroundStyle(.primary)
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
                                // Sua lógica original restaurada
                                withAnimation {
                                    if abertas.contains(categoria.nome) {
                                        abertas.remove(categoria.nome)
                                    } else {
                                        abertas.insert(categoria.nome)
                                    }
                                }
                            } onToggleItem: { item in
                                // Sua lógica original restaurada
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
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .padding(.bottom, 8)

                    TextField(
                        "",
                        text: $vm.viagem.outraAtividade,
                        prompt: Text("E.g. Photography, formal dinner...")
                            .foregroundColor(.primary),
                        axis: .vertical
                    )
                    .focused($isTextFieldFocused)
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
            .scrollDismissesKeyboard(.interactively)
            .adaptsToKeyboard()

            BotaoContinuarView(ativo: temSelecao) {
                PostHogSDK.shared.capture("onboarding_step3_completed", properties: [
                    "trip_type": vm.viagem.tipoViagem.rawValue,
                    "activities": vm.viagem.atividades,
                    "activities_count": vm.viagem.atividades.count,
                    "has_custom_activity": !vm.viagem.outraAtividade.isEmpty
                ])
                vm.avancar(para: 4)
            }
            .padding(40)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onTapGesture {
            isTextFieldFocused = false
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
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        if !aberta {
                            let itensAtivos = categoria.itens.filter { selecionadas.contains($0) }
                            Text(itensAtivos.isEmpty ? "No activities selected yet" : itensAtivos.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.primary)
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
                    Text("Select options:")
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
    
    let colunas = [GridItem(.adaptive(minimum: 100), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: colunas, alignment: .leading, spacing: 8) {
            ForEach(itens, id: \.self) { item in
                let ativo = selecionados.contains(item)
                
                Button {
                    onToggle(item)
                } label: {
                    Text(item)
                        .font(.body)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(ativo ? Color("RoxoClaro") : Color.primary.opacity(0.10))
                        .foregroundStyle(ativo ? Color.black : Color.primary)
                        .cornerRadius(20)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct AdaptsToKeyboard: ViewModifier {
    @State var currentHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .padding(.bottom, self.currentHeight)
                .onAppear(perform: {
                    NotificationCenter.Publisher(center: NotificationCenter.default, name: UIResponder.keyboardWillShowNotification)
                        .merge(with: NotificationCenter.Publisher(center: NotificationCenter.default, name: UIResponder.keyboardWillChangeFrameNotification))
                        .compactMap { notification in
                            withAnimation(.easeOut(duration: 0.16)) {
                                notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
                            }
                    }
                    .map { rect in
                        rect.height - geometry.safeAreaInsets.bottom
                    }
                    .subscribe(Subscribers.Assign(object: self, keyPath: \.currentHeight))
                    
                    NotificationCenter.Publisher(center: NotificationCenter.default, name: UIResponder.keyboardWillHideNotification)
                        .compactMap { notification in
                            CGFloat.zero
                    }
                    .subscribe(Subscribers.Assign(object: self, keyPath: \.currentHeight))
                })
        }
    }
}

extension View {
    func adaptsToKeyboard() -> some View {
        return modifier(AdaptsToKeyboard())
    }
}
