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
    @Environment(\.colorScheme) private var colorScheme
    @State private var locService = LocationService()

    // No dark mode o branco translúcido sobre o fundo escuro já bate com o
    // design; no light mode a mesma opacidade fica quase invisível sobre um
    // fundo claro, então os campos precisam ser branco sólido (#FFFFFF).
    private var corFundoCampo: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.white
    }

    var body: some View {
        @Bindable var vm = vm

        ZStack(alignment: .bottom) {
            
            Image("AppFundaTelaPerguntas")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    StepIndicatorView(etapaAtual: 1, totalEtapas: 4)
                        .padding(.bottom, 24)

                    Text("Where are you going?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.primary)

                    Text("Enter your destination and travel dates.")
                        .font(.body)
                        .foregroundStyle(.primary)
                        .padding(.top, 8)
                        .padding(.bottom, 24)

                    // MARK: DESTINATION
                    VStack(alignment: .leading, spacing: 8) {
                        Label {
                            Text("DESTINATION").tracking(0.8)
                        } icon: {
                            Image(systemName: "location.circle")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)

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
                        .background(corFundoCampo)
                        .cornerRadius(26)

                        if !locService.sugestoes.isEmpty &&
                            locService.busca != vm.viagem.destino {

                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(locService.sugestoes.prefix(5), id: \.self) { sugestao in
                                    Button {
                                        vm.viagem.destino = sugestao.title
                                        locService.busca = sugestao.title
                                        locService.sugestoes = []

                                        PostHogSDK.shared.capture(
                                            "onboarding_destination_set",
                                            properties: ["destination": sugestao.title]
                                        )

                                        UIApplication.shared.sendAction(
                                            #selector(UIResponder.resignFirstResponder),
                                            to: nil, from: nil, for: nil
                                        )
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(sugestao.title)
                                                .font(.body)
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
                            .background(corFundoCampo)
                            .cornerRadius(AppLayout.raioCantos)
                        }
                    }
                    .padding(.bottom, 20)

                    // MARK: TRAVEL DATES
                    VStack(alignment: .leading, spacing: 8) {
                        Label {
                            Text("TRAVEL DATES").tracking(0.8)
                        } icon: {
                            Image(systemName: "calendar")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)

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
                        .background(corFundoCampo)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }

                    Color.clear.frame(height: AppLayout.alturaBotao + 100)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppLayout.espacamento)
                .padding(.top, 80)
            }

            // MARK: Botão fixo
            BotaoContinuarView(ativo: !vm.viagem.destino.isEmpty) {
                PostHogSDK.shared.capture("onboarding_step1_completed", properties: [
                    "destination": vm.viagem.destino,
                    "days": vm.viagem.quantidadeDias
                ])
                vm.avancar(para: 2)
                
            }
            .padding(.bottom, 40)
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

// MARK: - StepIndicatorView

struct StepIndicatorView: View {
    let etapaAtual: Int
    let totalEtapas: Int

    // Traços finos e largos (não bolinhas): a etapa atual fica mais larga
    // que as demais pra se destacar, todas com a mesma altura baixa.
    private let alturaTraco: CGFloat = 4
    private let larguraAtiva: CGFloat = 36
    private let larguraInativa: CGFloat = 24

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalEtapas, id: \.self) { i in
                RoundedRectangle(cornerRadius: alturaTraco / 2)
                    .fill(i <= etapaAtual ? Color("Button") : Color.primary.opacity(0.25))
                    .frame(width: i == etapaAtual ? larguraAtiva : larguraInativa, height: alturaTraco)
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

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        Button(action: acao) {
            Text(rotulo)
                .font(.body)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
        }
        .background(
            ativo ? Color("Button") : Color.primary.opacity(0.12)
        )
        .foregroundStyle(
            ativo ? Color("ButtonLabel") : Color.primary.opacity(0.35)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: AppLayout.raioBotao,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.raioBotao)
                .strokeBorder(
                    ativo ? Color("StrokeButtonDark") : Color.clear,
                    lineWidth: 1
                )
        )
        .disabled(!ativo)
        .padding(.horizontal, AppLayout.espacamento)
        .padding(.top, 12)
        .padding(.bottom, isPad ? 34 : 34)
        .offset(y: isPad ? -70 : 0)
    }
}
