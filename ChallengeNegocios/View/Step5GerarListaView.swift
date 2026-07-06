//
//  Step5GerarListaView.swift
//  ChallengeNegocios
//
//  Created by Alana Queiroz on 26/03/26.
//

import SwiftUI
import PostHog
internal import Combine

struct Step5GerarListaView: View {
    @Environment(OnboardingViewModel.self) private var onboardingVM
    @Environment(ViagemStore.self) private var store

    var fecharOnboarding: () -> Void

    @State private var checklistVM = ChecklistViewModel()
    @State private var currentIndex = 0
    /// Referência da viagem já persistida na store (preenchida em `salvarViagem()`).
    /// Enquanto for `nil`, a lista ainda não existe na store — não há o que sincronizar.
    @State private var viagemSalva: Viagem? = nil

    let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
    let indexLimite = 4

    var body: some View {
        ZStack {
            if checklistVM.carregando && checklistVM.itens.isEmpty {
                loadingView
            } else {
                MainChecklistView(
                    vm: checklistVM,
                    onVoltar: fecharOnboarding
                )
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .task {
            checklistVM.configurar(com: onboardingVM.viagem)
            await checklistVM.gerarLista()
        }
        // Auto-salva quando terminar de gerar
        .onChange(of: checklistVM.carregando) { _, carregando in
            if !carregando && !checklistVM.itens.isEmpty {
                salvarViagem()
            }
        }
        // Se a pessoa marcar/desmarcar item, mudar quantidade ou adicionar
        // algo ainda nesta tela (depois da lista já ter sido salva), sincroniza
        // de volta com a store — senão essas alterações somem ao sair daqui.
        .onChange(of: checklistVM.itens) { _, novosItens in
            guard var viagem = viagemSalva else { return }
            viagem.itens = novosItens
            store.atualizar(viagem)
            viagemSalva = viagem
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        ZStack {
            Image("AppFundaTelaPerguntas")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image("anima\(currentIndex % (indexLimite + 1))")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 220, maxHeight: 220)
                    .onReceive(timer) { _ in
                        currentIndex += 1
                    }

                VStack(spacing: 8) {
                    Text("Building your packing list")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.primary)

                    Text("Making sure you won't forget a thing...")
                        .font(.body)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .padding(.horizontal, AppLayout.espacamento)
        }
    }

    // MARK: - Auto-salvar (silencioso, sem navegar)

    private func salvarViagem() {
        var viagem = onboardingVM.viagem
        viagem.itens         = checklistVM.itens
        viagem.tempMin       = checklistVM.tempMin
        viagem.tempMax       = checklistVM.tempMax
        viagem.condicaoClima = checklistVM.condicaoClima
        viagem.estacao       = checklistVM.estacao
        store.adicionar(viagem)
        viagemSalva = viagem
        PostHogSDK.shared.capture("trip_saved", properties: [
            "destination": viagem.destino,
            "days": viagem.quantidadeDias,
            "items_count": viagem.itens.count
        ])
    }
}
