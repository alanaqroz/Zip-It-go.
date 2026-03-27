//
//  AppTheme.swift
//  ChallengeNegocios
//
//  Created by Alana Queiroz on 26/03/26.
//

import SwiftUI

// MARK: - Cores

extension Color {
    static let appFundo           = Color(.systemBackground)   // fundo das telas
    static let appFundoSecundario = Color(.systemGray6)        // campos e cards
    static let appDestaque        = Color.black                 // cor principal (ativa, selecionado)
    static let appBotaoFundo      = Color(.systemGray5)        // fundo do botão Continuar
    static let appBotaoTexto      = Color.primary              // texto do botão
    static let appTextoSecundario = Color.secondary            // textos auxiliares
}

// MARK: - Layout
// Altere os valores abaixo para ajustar espaçamentos e tamanhos.

enum AppLayout {
    static let espacamento: CGFloat        = 24   // margem lateral das telas
    static let espacamentoInterno: CGFloat = 16   // padding dentro de cards
    static let espacamentoItens: CGFloat   = 12   // espaço entre itens de lista
    static let raioCantos: CGFloat         = 14   // arredondamento de cards e botões
    static let alturaBotao: CGFloat        = 56   // altura dos botões principais
    static let alturaIndicador: CGFloat    = 4    // espessura dos dots de progresso
}
