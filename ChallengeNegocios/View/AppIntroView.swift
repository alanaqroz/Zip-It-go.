//
//  AppIntroView.swift
//  ChallengeNegocios
//

import SwiftUI

private let W = UIScreen.main.bounds.width
private let H = UIScreen.main.bounds.height

// MARK: - Container principal
// FundoOnboarding fica FORA do TabView → não desliza durante a transição

struct AppIntroView: View {
    var aoConcluir: () -> Void
    @State private var pagina = 0

    var body: some View {
        ZStack(alignment: .bottom) {

            // ── 1. Fundo FIXO (não se move durante o swipe) ─────────────────
            Image("FundoOnboarding")
                .resizable()
                .scaledToFill()
                .frame(width: W, height: H)
                .clipped()
                .ignoresSafeArea()

            // ── 2. Conteúdo das páginas ──────────────────────────────────────
            TabView(selection: $pagina) {
                Pagina1().tag(0)
                Pagina2().tag(1)
                Pagina3().tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // ── 3. Controles FIXOS na mesma posição em todas as páginas ──────
            VStack(spacing: 0) {
                // Dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i == pagina
                                  ? Color("Button")
                                  : Color.primary.opacity(0.30))
                            .frame(width: i == pagina ? 8 : 6,
                                   height: i == pagina ? 8 : 6)
                            .animation(.spring(duration: 0.3), value: pagina)
                    }
                }
                .padding(.bottom, 48)

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
                    .padding(.horizontal, 40)
                } else {
                    Button(action: aoConcluir) {
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
                    .padding(.horizontal, 40)
                }
            }
            .padding(.bottom, 40)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Página 1
// Conteúdo: ImageOnboarding (menor) + texto
// Fundo vem do container fixo

private struct Pagina1: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Imagem — 44 % da altura, padding de 60 pt do topo
            Image("ImageOnboarding")
                .resizable()
                .scaledToFit()
                .frame(width: W, height: H * 0.44)
                .padding(.top, 60)

            Spacer().frame(height: 64)

            // Texto
            VStack(alignment: .leading, spacing: 16) {
                Text("Pack your suitcase in\nminutes.")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.primary)

                Text("Zip It! creates a personalized list of everything you need to take on your trip—so you don't forget a thing.")
                    .font(.body)
                    .foregroundStyle(.primary.opacity(0.80))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 40)

            // Espaço reservado para os controles fixos externos
            Spacer(minLength: 200)
        }
        .frame(width: W, height: H, alignment: .top)
    }
}

// MARK: - Página 2
// Camadas (de baixo para cima):
//   lookScreen (celular, menor, centralizado) →
//   ImageOb2 (cards flutuantes) →
//   GradientOnboarding2 (tela toda) →
//   texto

private struct Pagina2: View {
    var body: some View {
        ZStack(alignment: .top) {

            // 1. Celular — 54 % da largura, verticalmentecentralizado na metade superior
            Image("lookScreen")
                .resizable()
                .scaledToFit()
                .frame(width: W * 0.54)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, H * 0.04)

            // 2. Cards flutuantes — 80 % da largura, sobrepostos ao celular
            Image("ImageOb2")
                .resizable()
                .scaledToFit()
                .frame(width: W * 0.80)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, H * 0.15)

            // 3. Gradiente — tela INTEIRA (cobre celular + cards, cria contraste para o texto)
//            Image("GradientOnboarding2")
//                .resizable()
//                .scaledToFill()
//                .frame(width: W, height: H)
//                .clipped()

            // 4. Texto — posicionado na parte inferior sobre o gradiente
            VStack(alignment: .leading, spacing: 16) {
                Text("Every trip is unique.\nSo is your list.")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.primary)

                Text("We take into account the destination's climate, the time of year, your activities, and who's traveling with you.")
                    .font(.body)
                    .foregroundStyle(.primary.opacity(0.80))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 40)
            .padding(.top, H * 0.54)
        }
        .frame(width: W, height: H)
    }
}

// MARK: - Página 3
// Conteúdo: ImagneOnBoarding3 (menor, topo) + texto
// Fundo vem do container fixo + gradiente suave inferior

private struct Pagina3: View {
    var body: some View {
        ZStack(alignment: .top) {

            // Gradiente suave na parte inferior (complementa o fundo)
            LinearGradient(
                colors: [.clear, .black.opacity(0.45)],
                startPoint: .init(x: 0.5, y: 0.38),
                endPoint: .bottom
            )
            .frame(width: W, height: H)

            // Conteúdo
            VStack(alignment: .leading, spacing: 0) {

                // Imagem — 38 % da altura, padding de 60 pt do topo
                Image("ImagneOnBoarding3")
                    .resizable()
                    .scaledToFit()
                    .frame(width: W * 0.90, height: H * 0.38)
                    .frame(width: W, alignment: .center)
                    .padding(.top, 60)

                Spacer().frame(height: 40)

                // Texto
                VStack(alignment: .leading, spacing: 16) {
                    Text("Travel worry-free.")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.primary)

                    Text("Plan your suitcase ahead of time and have everything organized before you even step out the door.")
                        .font(.body)
                        .foregroundStyle(.primary.opacity(0.80))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 40)

                // Espaço para os controles externos
                Spacer(minLength: 200)
            }
        }
        .frame(width: W, height: H)
    }
}
