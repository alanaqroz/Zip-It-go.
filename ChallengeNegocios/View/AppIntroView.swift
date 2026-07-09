//
//  AppIntroView.swift
//  ChallengeNegocios
//

import SwiftUI

// MARK: - Modelo de Dados
struct OnboardingItem: Identifiable {
    let id = UUID()
    let asset: String
    let titulo: String
    let descricao: String
}

// MARK: - Container principal
struct AppIntroView: View {
    var aoConcluir: () -> Void
    @State private var pagina = 0

    // Lista de páginas
        private let paginas: [OnboardingItem] = [
            OnboardingItem(asset: "onboarding1", titulo: "Pack your suitcase in\nminutes.", descricao: "Zip It! creates a personalized list of everything you need to take on your trip—so you don't forget a thing."),
            OnboardingItem(asset: "onboarding2", titulo: "Every trip is unique.\nSo is your list.", descricao: "We take into account the destination's climate, the time of year, your activities, and who's traveling with you."),
            OnboardingItem(asset: "onboarding3", titulo: "Travel worry-free.", descricao: "Plan your suitcase ahead of time and have everything organized before you even step out the door.")
        ]
        
        private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
        private var bottomPadding: CGFloat { isPad ? 80 : 40 }
        private var horizontalPadding: CGFloat { isPad ? 60 : 40 }
    
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $pagina) {
                // Loop das paginas
                ForEach(Array(paginas.enumerated()), id: \.element.id) { index, item in
                    PaginaOnboarding(
                        asset: item.asset,
                        titulo: item.titulo,
                        descricao: item.descricao
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Dots
                HStack(spacing: 8) {
                    ForEach(0..<paginas.count, id: \.self) { i in
                        Circle()
                            .fill(i == pagina ? Color("Button") : Color("Button").opacity(0.30))
                            .frame(width: i == pagina ? 8 : 6, height: i == pagina ? 8 : 6)
                            .animation(.spring(duration: 0.3), value: pagina)
                    }
                }
                .padding(.bottom, 32)

                // Ações
                if pagina < (paginas.count - 1) {
                    HStack {
                        Button("Skip") { aoConcluir() }
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        Spacer()

                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) { pagina += 1 }
                        } label: {
                            Text("Next")
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundStyle(Color("ButtonLabel"))
                                .padding(.horizontal, 40)
                                .padding(.vertical, 16)
                                .background(Color("Button"))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                } else {
                    Button(action: aoConcluir) {
                        HStack(spacing: 6) {
                            Text("Create my first free list")
                            Image(systemName: "chevron.right")
                        }
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("ButtonLabel"))
                        .frame(maxWidth: isPad ? 480 : 354)
                        .frame(height: 52)
                        .background(Color("Button"))
                        .clipShape(Capsule())
                    }
                    .padding(.horizontal, isPad ? 60 : 18)
                }
            }
            .padding(.bottom, bottomPadding)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Página genérica

private struct PaginaOnboarding: View {
    let asset: String
    let titulo: String
    let descricao: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {

            // Fundo
            Image(asset)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
                .accessibilityHidden(true)


            // Texto na parte inferior
            VStack(alignment: .leading, spacing: 16) {
                Text(titulo)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.primary)

                Text(descricao)
                    .font(.body)
                    .foregroundStyle(.primary.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 200)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
