//
//  Step1DestinoView.swift
//
//  Created by Alana Queiroz on 25/03/26.
//

import SwiftUI
import MapKit
import PostHog

struct Step1DestinoView: View {
    @Environment(OnboardingViewModel.self) private var vm
    @State private var locService = LocationService()

    var body: some View {
        @Bindable var vm = vm

        ZStack {
            // MARK: Background
            Image("AppFundaTelaPerguntas")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // MARK: Conteúdo com botão
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // Indicador de etapas
                    StepIndicatorView(etapaAtual: 1, totalEtapas: 4)
                        .padding(.bottom, 24)

                    // Título
                    Text("Where are you going?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.primary)

                    // Subtítulo
                    Text("Enter your destination and travel dates.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                        .padding(.bottom, 24)

                    // MARK: Seção DESTINATION
                    VStack(alignment: .leading, spacing: 8) {
                        Label {
                            Text("DESTINATION").tracking(0.8)
                        } icon: {
                            Image(systemName: "location.north.fill")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                        // Campo de busca
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField(
                                "",
                                text: $locService.busca,
                                prompt: Text("Search a destination...")
                                    .foregroundColor(.secondary)
                            )
                            .foregroundStyle(.primary)
                            .autocorrectionDisabled()
                        }
                        .padding(.horizontal, AppLayout.espacamentoInterno)
                        .padding(.vertical, 14)
                        .background(.regularMaterial)
                        .cornerRadius(AppLayout.raioCantos)

                        // Sugestões
                        if !locService.sugestoes.isEmpty && locService.busca != vm.viagem.destino {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(locService.sugestoes.prefix(5), id: \.self) { sugestao in
                                    Button {
                                        vm.viagem.destino = sugestao.title
                                        locService.busca = sugestao.title
                                        locService.sugestoes = []
                                        PostHogSDK.shared.capture("onboarding_destination_set",
                                            properties: ["destination": sugestao.title])
                                        UIApplication.shared.sendAction(
                                            #selector(UIResponder.resignFirstResponder),
                                            to: nil, from: nil, for: nil
                                        )
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(sugestao.title)
                                                .font(.subheadline)
                                                .foregroundStyle(.primary)
                                            if !sugestao.subtitle.isEmpty {
                                                Text(sugestao.subtitle)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, AppLayout.espacamentoInterno)
                                        .padding(.vertical, 10)
                                    }
                                    if sugestao != locService.sugestoes.prefix(5).last {
                                        Divider().padding(.leading, AppLayout.espacamentoInterno)
                                    }
                                }
                            }
                            .background(.regularMaterial)
                            .cornerRadius(AppLayout.raioCantos)
                        }
                    }
                    .padding(.bottom, 20)

                    // MARK: Seção TRAVEL DATES
                    VStack(alignment: .leading, spacing: 8) {
                        Label {
                            Text("TRAVEL DATES").tracking(0.8)
                        } icon: {
                            Image(systemName: "calendar")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                        VStack(spacing: 0) {
                            HStack {
                                Text("Departure").foregroundStyle(.primary)
                                Spacer()
                                DatePicker("", selection: $vm.viagem.dataIda, displayedComponents: .date)
                                    .labelsHidden()
                            }
                            .padding(.horizontal, AppLayout.espacamentoInterno)
                            .padding(.vertical, 14)

                            Divider().padding(.horizontal, AppLayout.espacamentoInterno)

                            HStack {
                                Text("Return").foregroundStyle(.primary)
                                Spacer()
                                DatePicker(
                                    "",
                                    selection: $vm.viagem.dataVolta,
                                    in: vm.viagem.dataIda...,
                                    displayedComponents: .date
                                )
                                .labelsHidden()
                            }
                            .padding(.horizontal, AppLayout.espacamentoInterno)
                            .padding(.vertical, 14)
                        }
                        .background(.regularMaterial)
                        .cornerRadius(AppLayout.raioCantos)
                    }
                }
                .padding(.horizontal, AppLayout.espacamento)
                .padding(.top, 80)
                .padding(.bottom, AppLayout.alturaBotao + 60)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                // MARK: Botão fixo no rodapé
                BotaoContinuarView(ativo: !vm.viagem.destino.isEmpty) {
                    PostHogSDK.shared.capture("onboarding_step1_completed", properties: [
                        "destination": vm.viagem.destino,
                        "days": vm.viagem.quantidadeDias
                    ])
                    vm.avancar(para: 2)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - StepIndicatorView

struct StepIndicatorView: View {
    let etapaAtual: Int
    let totalEtapas: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...totalEtapas, id: \.self) { i in
                RoundedRectangle(cornerRadius: AppLayout.alturaIndicador / 2)
                    .fill(i <= etapaAtual ? Color("Button") : Color.primary.opacity(0.25))
                    .frame(width: 20, height: AppLayout.alturaIndicador)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - BotaoContinuarView

struct BotaoContinuarView: View {
    let ativo: Bool
    var rotulo: String = "Continue"
    let acao: () -> Void

    var body: some View {
        Button(action: acao) {
            Text(rotulo)
                .font(.headline)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .frame(height: AppLayout.alturaBotao)
                .background(
                    ativo ? Color("Button") : Color.primary.opacity(0.12)
                )
                .foregroundStyle(
                    ativo ? Color("ButtonLabel") : Color.primary.opacity(0.35)
                )
                .cornerRadius(AppLayout.raioBotao)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.raioBotao)
                        .strokeBorder(
                            ativo ? Color("StrokeButtonDark") : Color.clear,
                            lineWidth: 1
                        )
                )
        }
        .disabled(!ativo)
        .padding(.horizontal, AppLayout.espacamento)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .ignoresSafeArea(.container, edges: .bottom)
    }
}
