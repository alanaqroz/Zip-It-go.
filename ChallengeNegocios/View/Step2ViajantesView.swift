//
//  Step2ViajantesView.swift
//  ChallengeNegocios
//
//  Created by Alana Queiroz on 26/03/26.
//

import SwiftUI

struct Step2ViajantesView: View {
    @Environment(OnboardingViewModel.self) private var vm

    var body: some View {
        @Bindable var vm = vm

        ZStack(alignment: .bottom) {

            ScrollView {
                VStack(alignment: .leading, spacing: AppLayout.espacamento) {

                    StepIndicatorView(etapaAtual: 2, totalEtapas: 4)

                    // Título
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Quem vai viajar?")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Textinho explicativo.")
                            .font(.subheadline)
                            .foregroundColor(.appTextoSecundario)
                    }

                    // Seleção Solo / Grupo
                    HStack(spacing: 12) {
                        TipoGrupoCardView(
                            icone: "person.fill",
                            titulo: "Solo",
                            selecionado: vm.viagem.tipoGrupo == .solo
                        ) {
                            vm.viagem.tipoGrupo = .solo
                        }

                        TipoGrupoCardView(
                            icone: "person.3.fill",
                            titulo: "Grupo",
                            selecionado: vm.viagem.tipoGrupo == .grupo
                        ) {
                            vm.viagem.tipoGrupo = .grupo
                            // Garante ao menos 1 adulto no grupo
                            if vm.viagem.numAdultos < 1 { vm.viagem.numAdultos = 1 }
                        }
                    }

                    // Contadores — aparecem apenas quando Grupo está selecionado
                    if vm.viagem.tipoGrupo == .grupo {
                        VStack(spacing: 0) {
                            ContadorView(
                                titulo: "Adultos",
                                descricao: "Com 13 anos ou mais",
                                valor: $vm.viagem.numAdultos,
                                minimo: 1
                            )

                            Divider().padding(.leading, AppLayout.espacamento)

                            ContadorView(
                                titulo: "Crianças",
                                descricao: "Idades entre 2 e 12",
                                valor: $vm.viagem.numCriancas,
                                minimo: 0
                            )

                            Divider().padding(.leading, AppLayout.espacamento)

                            ContadorView(
                                titulo: "Bebês",
                                descricao: "Menos de 2 anos",
                                valor: $vm.viagem.numBebes,
                                minimo: 0
                            )
                        }
                        .background(Color.appFundoSecundario)
                        .cornerRadius(AppLayout.raioCantos)
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, AppLayout.espacamento)
                .padding(.top, AppLayout.espacamento)
            }

            BotaoContinuarView(ativo: true) {
                vm.avancar(para: 3)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Card Solo / Grupo

private struct TipoGrupoCardView: View {
    let icone: String
    let titulo: String
    let selecionado: Bool
    let acao: () -> Void

    var body: some View {
        Button(action: acao) {
            VStack(spacing: 10) {
                Image(systemName: icone)
                    .font(.title2)
                    .foregroundColor(selecionado ? .appBotaoTexto : .appTextoSecundario)
                Text(titulo)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(selecionado ? .appBotaoTexto : .appTextoSecundario)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(selecionado ? Color(.systemGray4) : Color.appFundoSecundario)
            .cornerRadius(AppLayout.raioCantos)
        }
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
                Text(descricao)
                    .font(.caption)
                    .foregroundColor(.appTextoSecundario)
            }

            Spacer()

            // Controles: número — botão_menos  número  botão_mais
            HStack(spacing: 16) {
                Button {
                    if valor > minimo { valor -= 1 }
                } label: {
                    Image(systemName: "minus")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(valor > minimo ? .primary : Color(.systemGray3))
                }
                .disabled(valor <= minimo)

                Text("\(valor)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(minWidth: 20, alignment: .center)

                Button {
                    valor += 1
                } label: {
                    Image(systemName: "plus")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.horizontal, AppLayout.espacamento)
        .padding(.vertical, 14)
    }
}
