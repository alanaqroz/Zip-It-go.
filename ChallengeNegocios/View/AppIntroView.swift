//
//  AppIntroView.swift
//  ChallengeNegocios
//

import SwiftUI

// MARK: - Intro principal

struct AppIntroView: View {
    var aoConcluir: () -> Void
    @State private var pagina = 0

    var body: some View {
        ZStack(alignment: .bottom) {

            // ── Páginas com swipe ────────────────────────────────────────────
            TabView(selection: $pagina) {
                PaginaIntro1().tag(0)
                PaginaIntro2().tag(1)
                PaginaIntro3(aoConcluir: aoConcluir).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // ── Controles fixos de navegação (só páginas 0 e 1) ──────────────
            if pagina < 2 {
                VStack(spacing: 0) {
                    // Indicador de página
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .fill(i == pagina ? Color("Button") : Color.white.opacity(0.45))
                                .frame(
                                    width: i == pagina ? 8 : 6,
                                    height: i == pagina ? 8 : 6
                                )
                                .animation(.spring(duration: 0.3), value: pagina)
                        }
                    }
                    .padding(.bottom, 48)

                    // Skip + Next
                    HStack {
                        Button("Pular") {
                            aoConcluir()
                        }
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                        Spacer()

                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                pagina += 1
                            }
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
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Página 1

private struct PaginaIntro1: View {
    var body: some View {
        ZStack {
            Image("fundoOnboarding")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Imagem central (ocupa parte superior)
                Image("imageOnboarding")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)

                Spacer(minLength: 64)

                // Textos
                VStack(alignment: .leading, spacing: 16) {
                    Text("Pack your suitcase in\nminutes.")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Zip It! creates a personalized list of everything you need to take on your trip—so you don't forget a thing.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 40)

                // Espaço para os controles fixos
                Spacer(minLength: 196)
            }
        }
    }
}

// MARK: - Página 2

private struct PaginaIntro2: View {
    var body: some View {
        ZStack {
            // Fundo base
            Image("fundoOnboarding")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // Overlay lookScreen
            Image("lookScreen")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.6)

            // Gradiente sobre os fundos (escurece a parte inferior)
            LinearGradient(
                colors: [.clear, .black.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Imagem central
                Image("imageOb2")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)

                Spacer(minLength: 0)

                // Textos
                VStack(alignment: .leading, spacing: 16) {
                    Text("Every trip is unique.\nSo is your list.")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)

                    Text("We take into account the destination's climate, the time of year, your activities, and who's traveling with you.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 40)

                Spacer(minLength: 196)
            }
        }
    }
}

// MARK: - Página 3

private struct PaginaIntro3: View {
    var aoConcluir: () -> Void

    var body: some View {
        ZStack {
            Image("fundoOnboarding")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // Gradiente suave no inferior
            LinearGradient(
                colors: [.clear, .black.opacity(0.65)],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Imagem central
                Image("imageOb3")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                    .padding(.horizontal, 20)

                Spacer(minLength: 0)

                // Textos
                VStack(alignment: .leading, spacing: 16) {
                    Text("Travel worry-free.")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Plan your suitcase ahead of time and have everything organized before you even step out the door.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 40)

                // Indicador de página + botão CTA
                VStack(spacing: 0) {
                    // Dots
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .fill(i == 2 ? Color("Button") : Color.white.opacity(0.45))
                                .frame(width: i == 2 ? 8 : 6, height: i == 2 ? 8 : 6)
                        }
                    }
                    .padding(.bottom, 48)

                    // Botão full-width CTA
                    Button {
                        aoConcluir()
                    } label: {
                        HStack(spacing: 6) {
                            Text("Create my first free list")
                            Image(systemName: "chevron.right")
                        }
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(Color("ButtonLabel"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color("Button"))
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 48)
                .padding(.bottom, 40)
            }
        }
    }
}
