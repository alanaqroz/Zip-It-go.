//
//  AppIntroView.swift
//  ChallengeNegocios
//

import SwiftUI

private let W = UIScreen.main.bounds.width
private let H = UIScreen.main.bounds.height

// MARK: - Container principal

struct AppIntroView: View {
    var aoConcluir: () -> Void
    @State private var pagina = 0

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var bottomPadding: CGFloat { isPad ? 80 : 40 }
    private var horizontalPadding: CGFloat { isPad ? 60 : 40 }

    var body: some View {
        ZStack(alignment: .bottom) {

            TabView(selection: $pagina) {
                PaginaOnboarding(
                    asset: "onboarding1",
                    titulo: "Pack your suitcase in\nminutes.",
                    descricao: "Zip It! creates a personalized list of everything you need to take on your trip—so you don't forget a thing."
                ).tag(0)

                PaginaOnboarding(
                    asset: "onboarding2",
                    titulo: "Every trip is unique.\nSo is your list.",
                    descricao: "We take into account the destination's climate, the time of year, your activities, and who's traveling with you."
                ).tag(1)

                PaginaOnboarding(
                    asset: "onboarding3",
                    titulo: "Travel worry-free.",
                    descricao: "Plan your suitcase ahead of time and have everything organized before you even step out the door."
                ).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i == pagina ? Color("Button") : Color.white.opacity(0.50))
                            .frame(width: i == pagina ? 8 : 6,
                                   height: i == pagina ? 8 : 6)
                            .animation(.spring(duration: 0.3), value: pagina)
                    }
                }
                .padding(.bottom, 32)

                // Ações
                if pagina < 2 {
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
                        .fontWeight(.bold)
                        .foregroundStyle(Color("ButtonLabel"))
                        .frame(maxWidth: isPad ? 480 : .infinity)
                        .padding(.vertical, 18)
                        .background(Color("Button"))
                        .clipShape(Capsule())
                    }
                    .padding(.horizontal, horizontalPadding)
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

            // Fundo completo — a imagem já contém background + ilustração
            Image(asset)
                .resizable()
                .scaledToFill()
                .frame(width: W, height: H)
                .clipped()
                .ignoresSafeArea()


            // Texto posicionado na parte inferior
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
        .frame(width: W, height: H)
    }
}
