//
//  Formatters.swift
//  ChallengeNegocios
//
//  DateFormatters compartilhados e reutilizados pelo app.
//
//  Criar um DateFormatter é uma operação relativamente cara (carrega
//  dados de calendário/locale). Váras views/models estavam instanciando
//  um DateFormatter novo a cada render (em computed properties chamadas
//  pelo body). Centralizar como `static let` garante que cada formato
//  seja construído uma única vez e reaproveitado.
//

import Foundation

extension DateFormatter {
    /// "dd MMM" — usado no resumo do período da viagem (ex: Viagem.periodoFormatado).
    static let diaMes: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "dd MMM"
        return fmt
    }()

    /// "dd/MM" — usado no período do checklist (ChecklistViewModel.periodoFormatado).
    static let diaMesBarra: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "dd/MM"
        return fmt
    }()

    /// "yyyy" — ano isolado, usado junto com `diaMesBarra`.
    static let ano: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy"
        return fmt
    }()

    /// "d MMM" em en_US — usado nos cards de viagem da Home (CardViagemView).
    static let diaMesCard: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM"
        fmt.locale = Locale(identifier: "en_US")
        return fmt
    }()

    /// "MMMM" — nome do mês, usado como fallback de clima quando o WeatherKit falha.
    static let mesCompleto: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM"
        return fmt
    }()
}
