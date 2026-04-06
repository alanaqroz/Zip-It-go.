//
//  Step5GerarListaView.swift
//  ChallengeNegocios
//
//  Created by Alana Queiroz on 26/03/26.
//

import SwiftUI
import PostHog

struct Step5GerarListaView: View {
    @Environment(OnboardingViewModel.self) private var onboardingVM
    @Environment(ViagemStore.self) private var store

    var fecharOnboarding: () -> Void

    @State private var checklistVM = ChecklistViewModel()
    @State private var viagemSalva = false

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            if checklistVM.carregando && checklistVM.itens.isEmpty {
                loadingView
            } else {
                MainChecklistView(vm: checklistVM)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(checklistVM.carregando)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !checklistVM.itens.isEmpty {
                    Button(viagemSalva ? "Salvo ✓" : "Salvar") {
                        salvarViagem()
                    }
                    .disabled(viagemSalva)
                }
            }
        }
        .task {
            checklistVM.configurar(com: onboardingVM.viagem)
            await checklistVM.gerarLista()
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.3)

            VStack(spacing: 6) {
                Text("Gerando sua lista...")
                    .font(.headline)
                Text("Consultando clima em \(onboardingVM.viagem.destino)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }

    // MARK: - Salvar

    private func salvarViagem() {
        var viagem = onboardingVM.viagem
        viagem.itens         = checklistVM.itens
        viagem.tempMin       = checklistVM.tempMin
        viagem.tempMax       = checklistVM.tempMax
        viagem.condicaoClima = checklistVM.condicaoClima
        viagem.estacao       = checklistVM.estacao
        store.adicionar(viagem)
        PostHogSDK.shared.capture("trip_saved", properties: [
            "destination": viagem.destino,
            "days": viagem.quantidadeDias,
            "items_count": viagem.itens.count
        ])
        viagemSalva = true

        // Volta para a Home após breve pausa
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            fecharOnboarding()
        }
    }
}
