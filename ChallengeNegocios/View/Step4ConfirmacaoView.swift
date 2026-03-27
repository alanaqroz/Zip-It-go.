//
//  Step4ConfirmacaoView.swift
//  ChallengeNegocios
//
//  Created by Alana Queiroz on 26/03/26.
//

import SwiftUI

struct Step4ConfirmacaoView: View {
    @Environment(OnboardingViewModel.self) private var vm

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppLayout.espacamento) {

                StepIndicatorView(etapaAtual: 4, totalEtapas: 4)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Tudo certo?")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Revise os dados antes de gerar sua lista.")
                        .font(.subheadline)
                        .foregroundColor(.appTextoSecundario)
                }

                // Seção 1 — Destino
                ResumoSecaoView(titulo: "Destino") {
                    vm.editarEtapa(1)
                } conteudo: {
                    ResumoLinhaView(texto: vm.viagem.destino.isEmpty ? "—" : vm.viagem.destino)
                    ResumoLinhaView(texto: vm.viagem.periodoFormatado)
                    ResumoLinhaView(texto: "\(vm.viagem.quantidadeDias) dia\(vm.viagem.quantidadeDias > 1 ? "s" : "")")
                }

                // Seção 2 — Viajantes
                ResumoSecaoView(titulo: "Viajantes") {
                    vm.editarEtapa(2)
                } conteudo: {
                    ResumoLinhaView(texto: vm.viagem.tipoGrupo.rawValue)
                    if vm.viagem.tipoGrupo == .grupo {
                        ResumoLinhaView(texto: vm.viagem.resumoViajantes)
                    }
                }

                // Seção 3 — Tipo e atividades
                ResumoSecaoView(titulo: "Viagem") {
                    vm.editarEtapa(3)
                } conteudo: {
                    ResumoLinhaView(texto: vm.viagem.tipoViagem.rawValue)
                    if !vm.viagem.atividades.isEmpty || !vm.viagem.outraAtividade.trimmingCharacters(in: .whitespaces).isEmpty {
                        ResumoLinhaView(texto: vm.viagem.resumoAtividades)
                    }
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal, AppLayout.espacamento)
            .padding(.top, AppLayout.espacamento)
        }
        .safeAreaInset(edge: .bottom) {
            BotaoContinuarView(ativo: true, rotulo: "Gerar lista") {
                vm.avancar(para: 5)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Seção com título + botão Editar + conteúdo

private struct ResumoSecaoView<Conteudo: View>: View {
    let titulo: String
    let onEditar: () -> Void
    @ViewBuilder let conteudo: () -> Conteudo

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            HStack {
                Text(titulo)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Button("Editar", action: onEditar)
                    .font(.subheadline)
                    .foregroundColor(.appTextoSecundario)
            }
            .padding(.horizontal, AppLayout.espacamentoInterno)
            .padding(.vertical, 12)

            Divider()
                .padding(.leading, AppLayout.espacamentoInterno)

            conteudo()
        }
        .background(Color.appFundoSecundario)
        .cornerRadius(AppLayout.raioCantos)
    }
}

// MARK: - Linha de texto simples

private struct ResumoLinhaView: View {
    let texto: String

    var body: some View {
        HStack {
            Text(texto)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, AppLayout.espacamentoInterno)
        .padding(.vertical, 12)
    }
}
