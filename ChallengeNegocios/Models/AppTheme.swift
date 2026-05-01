//
//  AppTheme.swift
//  ChallengeNegocios
//
//  Created by Alana Queiroz on 26/03/26.
//

import SwiftUI

// MARK: - Cores

extension Color {
    // Onboarding — cores dos assets (adaptativas light/dark)
    static let appBotao            = Color("Button")            // fundo do botão principal
    static let appBotaoLabel       = Color("ButtonLabel")       // texto do botão
    static let appBotaoStroke      = Color("StrokeButtonDark")  // borda do botão
    static let appIcone            = Color("Icon")              // cor dos ícones de categoria
    static let appRoxoClaro        = Color("RoxoClaro")         // chip selecionado
    static let appFundoCampo       = Color.white.opacity(0.10)  // campos sobre fundo escuro
    static let appTextoSobre       = Color.white                // texto principal sobre fundo escuro
    static let appTextoLabel       = Color.white.opacity(0.50)  // labels de seção
    static let appSeparador        = Color.white.opacity(0.15)  // dividers dentro de cards

    // Home / listas — herdam do sistema
    static let appFundo            = Color(.systemBackground)
    static let appFundoSecundario  = Color(.systemGray6)
    static let appDestaque         = Color.black
    static let appBotaoFundo       = Color(.systemGray5)
    static let appBotaoTexto       = Color.primary
    static let appTextoSecundario  = Color.secondary
    static let appClimaFundo       = Color(.systemBackground)
}

// MARK: - Layout

enum AppLayout {
    static let espacamento: CGFloat        = 24   // margem lateral das telas
    static let espacamentoInterno: CGFloat = 16   // padding dentro de cards
    static let espacamentoItens: CGFloat   = 12   // espaço entre itens de lista
    static let raioCantos: CGFloat         = 14   // arredondamento de cards e botões
    static let raioBotao: CGFloat          = 28   // pill shape para botão principal
    static let alturaBotao: CGFloat        = 64   // altura dos botões principais
    static let alturaIndicador: CGFloat    = 8    // espessura dos dots de progresso
}
