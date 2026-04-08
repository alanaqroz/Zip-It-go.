//
//  Step2ViajantesView.swift
//
//  Created by Alana Queiroz on 25/03/26.
//

import SwiftUI
import PostHog

struct Step2ViajantesView: View {
    @Environment(OnboardingViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss
    @State private var temSelecao = false

    var body: some View {
        @Bindable var vm = vm

        ZStack {
            // MARK: Background
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

                        StepIndicatorView(etapaAtual: 2, totalEtapas: 4)
                            .frame(maxWidth: 160)

                        Spacer()

                        // Espaço espelho para balancear o botão voltar
                        Color.clear.frame(width: 40, height: 40)
                    }
                    .padding(.bottom, 24)

                    // MARK: Título
                    Text("How are you traveling?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.primary)

                    Text("Choose your profile so we can personalize your experience.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                        .padding(.bottom, 24)

                    // MARK: Cards Solo / Group
                    HStack(spacing: 18) {
                        TipoGrupoCardView(
                            icone: "person.fill",
                            titulo: "Solo",
                            selecionado: temSelecao && vm.viagem.tipoGrupo == .solo
                        ) {
                            vm.viagem.tipoGrupo = .solo
                            temSelecao = true
                        }

                        TipoGrupoCardView(
                            icone: "person.3.fill",
                            titulo: "Group",
                            selecionado: temSelecao && vm.viagem.tipoGrupo == .grupo
                        ) {
                            vm.viagem.tipoGrupo = .grupo
                            if vm.viagem.numAdultos < 1 { vm.viagem.numAdultos = 1 }
                            temSelecao = true
                        }
                    }

                    // MARK: Contadores (apenas modo Grupo)
                    if vm.viagem.tipoGrupo == .grupo {
                        VStack(spacing: 0) {
                            ContadorView(
                                titulo: "Adults",
                                descricao: "13 years or older",
                                valor: $vm.viagem.numAdultos,
                                minimo: 1
                            )
                            Divider().padding(.leading, AppLayout.espacamento)
                            ContadorView(
                                titulo: "Children",
                                descricao: "Ages 2 to 12",
                                valor: $vm.viagem.numCriancas,
                                minimo: 0
                            )
                            Divider().padding(.leading, AppLayout.espacamento)
                            ContadorView(
                                titulo: "Babies",
                                descricao: "Under 2 years",
                                valor: $vm.viagem.numBebes,
                                minimo: 0
                            )
                        }
                        .background(.regularMaterial)
                        .cornerRadius(AppLayout.raioCantos)
                        .padding(.top, 24)
                    }
                }
                .padding(.horizontal, AppLayout.espacamento)
                .padding(.top, 80)
                .padding(.bottom, AppLayout.alturaBotao + 24)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                BotaoContinuarView(ativo: temSelecao) {
                    PostHogSDK.shared.capture("onboarding_step2_completed", properties: [
                        "group_type": vm.viagem.tipoGrupo.rawValue,
                        "adults": vm.viagem.numAdultos,
                        "children": vm.viagem.numCriancas,
                        "babies": vm.viagem.numBebes
                    ])
                    vm.avancar(para: 3)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Card usando imagem do asset

private struct TipoGrupoCardView: View {
    let icone: String
    let titulo: String
    let selecionado: Bool
    let acao: () -> Void

    var body: some View {
        Button(action: acao) {
            ZStack {
                // Fundo — troca de asset ao selecionar, responsivo via GeometryReader
                Image(selecionado ? "CardFundoSelect" : "CardFundoNormal")
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)

                // Conteúdo vetorial sobreposto
                VStack(spacing: 10) {
                    Image(systemName: icone)
                        .font(.system(size: 28, weight: .medium))
                    Text(titulo)
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.primary)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            // aspectRatio garante card quadrado em qualquer tela
            .aspectRatio(1, contentMode: .fit)
            // frame(maxWidth: .infinity) junto com o HStack divide o espaço igualmente
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Contador de pessoas

private struct ContadorView: View {
    let titulo: String
    let descricao: String
    @Binding var valor: Int
    let minimo: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(titulo)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Text(descricao)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 16) {
                Button {
                    if valor > minimo { valor -= 1 }
                } label: {
                    Image(systemName: "minus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(valor > minimo ? .primary : Color.primary.opacity(0.3))
                }
                .disabled(valor <= minimo)

                Text("\(valor)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(minWidth: 20, alignment: .center)

                Button {
                    valor += 1
                } label: {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(.horizontal, AppLayout.espacamento)
        .padding(.vertical, 14)
    }
}
