//
//  ChallengeNegociosApp.swift
//
//  Created by Alana Queiroz on 25/03/26.
//

import SwiftUI
import PostHog
import RevenueCat

@main
struct ChallengeNegociosApp: App {
    @State private var store = ViagemStore()

    init() {
        // ── PostHog ────────────────────────────────────────────────────────
        let token = ProcessInfo.processInfo.environment["POSTHOG_PROJECT_TOKEN"] ?? ""
        let host  = ProcessInfo.processInfo.environment["POSTHOG_HOST"] ?? "https://app.posthog.com"

        if !token.isEmpty {
            let config = PostHogConfig(apiKey: token, host: host)
            config.captureApplicationLifecycleEvents = true
            PostHogSDK.shared.setup(config)
        }

        // ── RevenueCat ─────────────────────────────────────────────────────
        SubscriptionManager.shared.configure()
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
    /// Controla se as telas de intro (marketing) já foram exibidas
    @AppStorage("introShown")  private var introShown  = false
    /// Controla se as perguntas (Step1…Step5) já foram concluídas
    @AppStorage("primeiraVez") private var primeiraVez = true

    @State private var onboardingVM     = OnboardingViewModel()
    @State private var mostraOnboarding = false

    var body: some View {
        if !introShown {
            // ── 1ª abertura: telas de intro (marketing) ───────────────────
            AppIntroView {
                introShown = true
                // primeiraVez ainda é true → irá para as perguntas
            }
        } else if primeiraVez {
            // ── Intro vista mas perguntas ainda não concluídas ─────────────
            OnboardingContainerView {
                primeiraVez = false
            }
            .environment(onboardingVM)
        } else {
            // ── Aberturas normais: começa pela Home ───────────────────────
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
