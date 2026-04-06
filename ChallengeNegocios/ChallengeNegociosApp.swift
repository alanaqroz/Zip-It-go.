//
//  ChallengeNegociosApp.swift
//
//  Created by Alana Queiroz on 25/03/26.
//

import SwiftUI
import PostHog

@main
struct ChallengeNegociosApp: App {
    @State private var store = ViagemStore()

    init() {
        let token = ProcessInfo.processInfo.environment["POSTHOG_PROJECT_TOKEN"] ?? ""
        let host  = ProcessInfo.processInfo.environment["POSTHOG_HOST"] ?? "https://app.posthog.com"

        if !token.isEmpty {
            let config = PostHogConfig(apiKey: token, host: host)
            config.captureApplicationLifecycleEvents = true
            PostHogSDK.shared.setup(config)
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(store)
        }
    }
}

// MARK: - Raiz do app

struct AppRootView: View {
    @AppStorage("primeiraVez") private var primeiraVez = true
    @State private var onboardingVM     = OnboardingViewModel()
    @State private var mostraOnboarding = false

    var body: some View {
        if primeiraVez {
            // Primeira abertura: onboarding como tela raiz
            OnboardingContainerView {
                primeiraVez = false
            }
            .environment(onboardingVM)
        } else {
            // Aberturas seguintes: começa pela Home
            Step6HomeView(mostraOnboarding: $mostraOnboarding)
                .fullScreenCover(isPresented: $mostraOnboarding) {
                    OnboardingContainerView {
                        mostraOnboarding = false
                    }
                    .environment(onboardingVM)
                    .onDisappear {
                        onboardingVM.reiniciar()
                    }
                }
        }
    }
}

// MARK: - Container do onboarding

struct OnboardingContainerView: View {
    @Environment(OnboardingViewModel.self) private var vm
    var fecharOnboarding: () -> Void

    var body: some View {
        @Bindable var vm = vm
        NavigationStack(path: $vm.etapas) {
            Step1DestinoView()
                .navigationDestination(for: Int.self) { etapa in
                    switch etapa {
                    case 2: Step2ViajantesView()
                    case 3: Step3TipoViagemView()
                    case 4: Step4ConfirmacaoView()
                    case 5: Step5GerarListaView(fecharOnboarding: fecharOnboarding)
                    default: EmptyView()
                    }
                }
        }
    }
}
