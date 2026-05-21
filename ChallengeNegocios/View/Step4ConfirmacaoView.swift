//
//  Step4ConfirmacaoView.swift
//  ChallengeNegocios
//
//  Created by Alana Queiroz on 26/03/26.
//

import SwiftUI
import PostHog

struct Step4ConfirmacaoView: View {
    @Environment(OnboardingViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss
    @State private var mostraAlerta = false

    var body: some View {
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

                        StepIndicatorView(etapaAtual: 4, totalEtapas: 4)
                            .frame(maxWidth: 160)

                        Spacer()

                        Color.clear.frame(width: 40, height: 40)
                    }
                    .padding(.bottom, 24)

                    // MARK: Título
                    Text("Ready to go?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.primary)

                    Text("Review your details before we build your list.")
                        .font(.body)
                        .foregroundStyle(.primary)
                        .padding(.top, 8)
                        .padding(.bottom, 24)

                    // MARK: Card de resumo unificado
                    VStack(spacing: 0) {
                        ResumoLinhaView(
                            rotulo: "Destination",
                            valor: vm.viagem.destino.isEmpty ? "—" : vm.viagem.destino + "."
                        ) {
                            PostHogSDK.shared.capture("onboarding_section_edited", properties: ["section": "destination"])
                            vm.editarEtapa(1)
                        }

                        Divider().padding(.leading, AppLayout.espacamentoInterno)

                        ResumoLinhaView(
                            rotulo: "Dates",
                            valor: vm.viagem.periodoFormatado
                        ) {
                            PostHogSDK.shared.capture("onboarding_section_edited", properties: ["section": "destination"])
                            vm.editarEtapa(1)
                        }

                        Divider().padding(.leading, AppLayout.espacamentoInterno)

                        ResumoLinhaView(
                            rotulo: "Travelers",
                            valor: vm.viagem.tipoGrupo == .grupo
                                ? vm.viagem.resumoViajantes
                                : vm.viagem.tipoGrupo.rawValue
                        ) {
                            PostHogSDK.shared.capture("onboarding_section_edited", properties: ["section": "travelers"])
                            vm.editarEtapa(2)
                        }

                        Divider().padding(.leading, AppLayout.espacamentoInterno)

                        ResumoLinhaView(
                            rotulo: "Trip Type",
                            valor: vm.viagem.tipoViagem.rawValue
                        ) {
                            PostHogSDK.shared.capture("onboarding_section_edited", properties: ["section": "trip_type"])
                            vm.editarEtapa(3)
                        }

                        if !vm.viagem.atividades.isEmpty || !vm.viagem.outraAtividade.trimmingCharacters(in: .whitespaces).isEmpty {
                            Divider().padding(.leading, AppLayout.espacamentoInterno)

                            ResumoLinhaView(
                                rotulo: "Activities",
                                valor: vm.viagem.resumoAtividades + "."
                            ) {
                                PostHogSDK.shared.capture("onboarding_section_edited", properties: ["section": "trip_type"])
                                vm.editarEtapa(3)
                            }
                        }
                    }
                    .background(.regularMaterial)
                    .cornerRadius(24)
                    .padding(.bottom, 16)

                    // MARK: Banner aviso
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color("Button"))

                        Text("Please double-check your details. The list can't be edited once it's generated.")
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color("AlertButton"))
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(Color("StrokeAlertButton"), lineWidth: 1)
                    )
                    .padding(.bottom, AppLayout.alturaBotao + 32)
                }
                .padding(.horizontal, AppLayout.espacamento)
                .padding(.top, 80)
            }
            .scrollDismissesKeyboard(.immediately)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                BotaoContinuarView(ativo: true, rotulo: "✦  Generate My Packing List") {
                    mostraAlerta = true
                }
                .padding(.bottom, 40)
            }
            

            // MARK: Alerta inline
            if mostraAlerta {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { mostraAlerta = false }

                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        Text("Are you sure?")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.primary)

                        Text("Your list can't be changed after it's created.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 28)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                    VStack(spacing: 12) {
                        Button {
                            mostraAlerta = false
                            PostHogSDK.shared.capture("trip_list_generation_started", properties: [
                                "destination": vm.viagem.destino,
                                "days": vm.viagem.quantidadeDias,
                                "trip_type": vm.viagem.tipoViagem.rawValue,
                                "group_type": vm.viagem.tipoGrupo.rawValue
                            ])
                            vm.avancar(para: 5)
                        } label: {
                            Text("Generate List")
                                .font(.headline)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color("Button"))
                                .foregroundStyle(Color("ButtonLabel"))
                                .cornerRadius(AppLayout.raioBotao)
                        }

                        Button { mostraAlerta = false } label: {
                            Text("Go Back")
                                .font(.body)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.primary.opacity(0.10))
                                .foregroundStyle(.primary)
                                .cornerRadius(AppLayout.raioBotao)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .background(.regularMaterial)
                .cornerRadius(24)
                .padding(.horizontal, 24)
                .transition(.scale(scale: 0.92).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: mostraAlerta)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Linha de resumo

private struct ResumoLinhaView: View {
    let rotulo: String
    let valor: String
    let onEditar: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(rotulo)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(valor)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            Spacer()

            Button(action: onEditar) {
                HStack(spacing: 2) {
                    Text("Edit")
                        .font(.body)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(Color("Button"))
            }
        }
        .padding(.horizontal, AppLayout.espacamentoInterno)
        .padding(.vertical, 14)
    }
}
