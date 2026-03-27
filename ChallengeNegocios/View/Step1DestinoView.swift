//
//  Step1DestinoView.swift
//  ChallengeNegocios
//
//  Tela 1 — Destino e datas da viagem.
//

import SwiftUI
import MapKit

struct Step1DestinoView: View {
    @Environment(OnboardingViewModel.self) private var vm
    @State private var locService = LocationService()

    var body: some View {
        @Bindable var vm = vm

        ZStack(alignment: .bottom) {

            // MARK: Conteúdo rolável
            ScrollView {
                VStack(alignment: .leading, spacing: AppLayout.espacamento) {

                    StepIndicatorView(etapaAtual: 1, totalEtapas: 4)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Para onde você vai?")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Textinho explicativo.")
                            .font(.subheadline)
                            .foregroundColor(.appTextoSecundario)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Destino")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.appTextoSecundario)
                            TextField("Onde você deseja ir?", text: $locService.busca)
                                .autocorrectionDisabled()
                        }
                        .padding(.horizontal, AppLayout.espacamentoInterno)
                        .padding(.vertical, 13)
                        .background(Color.appFundoSecundario)
                        .cornerRadius(AppLayout.raioCantos)

                        if !locService.sugestoes.isEmpty && locService.busca != vm.viagem.destino {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(locService.sugestoes.prefix(5), id: \.self) { sugestao in
                                    Button {
                                        vm.viagem.destino = sugestao.title
                                        locService.busca = sugestao.title
                                        locService.sugestoes = []
                                        UIApplication.shared.sendAction(
                                            #selector(UIResponder.resignFirstResponder),
                                            to: nil, from: nil, for: nil
                                        )
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(sugestao.title)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                            if !sugestao.subtitle.isEmpty {
                                                Text(sugestao.subtitle)
                                                    .font(.caption)
                                                    .foregroundColor(.appTextoSecundario)
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
                            .background(Color.appFundo)
                            .cornerRadius(AppLayout.raioCantos)
                            .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
                        }
                    }

                    // Datas
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selecione a data")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        VStack(spacing: 0) {
                            // Ida
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.appTextoSecundario)
                                    .frame(width: 20)
                                Text("Ida")
                                Spacer()
                                DatePicker("", selection: $vm.viagem.dataIda, displayedComponents: .date)
                                    .labelsHidden()
                            }
                            .padding(.horizontal, AppLayout.espacamentoInterno)
                            .padding(.vertical, 13)

                            Divider().padding(.leading, AppLayout.espacamentoInterno)

                            // Volta
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.appTextoSecundario)
                                    .frame(width: 20)
                                Text("Volta")
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
                            .padding(.vertical, 13)
                        }
                        .background(Color.appFundoSecundario)
                        .cornerRadius(AppLayout.raioCantos)
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, AppLayout.espacamento)
                .padding(.top, AppLayout.espacamento)
            }

            // MARK: Botão Continuar
            BotaoContinuarView(ativo: !vm.viagem.destino.isEmpty) {
                vm.avancar(para: 2)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Componentes compartilhados entre as telas
struct StepIndicatorView: View {
    let etapaAtual: Int
    let totalEtapas: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...totalEtapas, id: \.self) { i in
                RoundedRectangle(cornerRadius: AppLayout.alturaIndicador / 2)
                    .fill(i <= etapaAtual ? Color.appDestaque : Color(.systemGray4))
                    .frame(width: i == etapaAtual ? 32 : 20, height: AppLayout.alturaIndicador)
                    .animation(.easeInOut(duration: 0.2), value: etapaAtual)
            }
            Spacer()
        }
    }
}

struct BotaoContinuarView: View {
    let ativo: Bool
    let acao: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: acao) {
                Text("Continuar")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppLayout.alturaBotao)
                    .background(ativo ? Color.appBotaoFundo : Color(.systemGray5))
                    .foregroundColor(ativo ? .appBotaoTexto : .appTextoSecundario)
                    .cornerRadius(AppLayout.raioCantos)
            }
            .disabled(!ativo)
            .padding(.horizontal, AppLayout.espacamento)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(.ultraThinMaterial)
    }
}
