//
//  ChallengeNegociosApp.swift
//  ChallengeNegocios
//

import SwiftUI

@main
struct ChallengeNegociosApp: App {
    @State private var store       = ViagemStore()
    @State private var onboardingVM = OnboardingViewModel()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(store)
                .environment(onboardingVM)
        }
    }
}

// MARK: - Raiz da NavigationStack
// Toda a navegação do onboarding passa por aqui.
// Adicione os casos novos em navigationDestination conforme as telas forem criadas.

struct AppRootView: View {
    @Environment(OnboardingViewModel.self) private var vm

    var body: some View {
        @Bindable var vm = vm
        NavigationStack(path: $vm.etapas) {
            Step1DestinoView()
                .navigationDestination(for: Int.self) { etapa in
                    switch etapa {
                    case 2: Text("Tela 2 — em breve")   // substituir por Step2ViajantesView()
                    case 3: Text("Tela 3 — em breve")   // substituir por Step3AtividadesView()
                    case 4: Text("Tela 4 — em breve")   // substituir por Step4ConfirmacaoView()
                    default: EmptyView()
                    }
                }
        }
    }
}
