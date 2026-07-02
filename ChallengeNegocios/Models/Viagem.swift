//
//  Viagem.swift
//  ChallengeNegocios
//
//  Created by Alana Queiroz on 26/03/26.
//

import Foundation

// MARK: - Enums

enum TipoGrupo: String, Codable, CaseIterable {
    case solo  = "Solo"
    case grupo = "Group"
}

enum TipoViagem: String, Codable, CaseIterable {
    case lazer    = "Leisure"
    case negocios = "Business"
}

// MARK: - Viagem

struct Viagem: Identifiable, Codable {
    var id: UUID = UUID()

    // Tela 1 — Destino
    var destino: String = ""
    var dataIda: Date   = Date()
    var dataVolta: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

    // Tela 2 — Quem vai
    var tipoGrupo:  TipoGrupo = .solo
    var numAdultos: Int = 1
    var numCriancas: Int = 0
    var numBebes:   Int = 0

    // Tela 3 — Tipo e atividades
    var tipoViagem:     TipoViagem = .lazer
    var atividades:     [String]   = []
    var outraAtividade: String     = ""

    // Tela 5 — Lista gerada
    var itens: [ItemMala] = []

    // Clima (salvo junto com a viagem)
    var tempMin: Double? = nil
    var tempMax: Double? = nil
    var condicaoClima: String = ""
    var estacao: String = ""

    // Controle
    var criadaEm: Date = Date()

    // MARK: Computed

    var quantidadeDias: Int {
        max(1, Calendar.current.dateComponents([.day], from: dataIda, to: dataVolta).day ?? 1)
    }

    var resumoViajantes: String {
        if tipoGrupo == .solo { return "Solo" }
        var partes: [String] = []
        if numAdultos  > 0 { partes.append("\(numAdultos) adult\(numAdultos > 1 ? "s" : "")") }
        if numCriancas > 0 { partes.append("\(numCriancas) kid\(numCriancas > 1 ? "s" : "")") }
        if numBebes    > 0 { partes.append("\(numBebes) baby\(numBebes > 1 ? "/babies" : "")") }
        return partes.joined(separator: " · ")
    }

    var resumoAtividades: String {
        var lista = atividades
        if !outraAtividade.trimmingCharacters(in: .whitespaces).isEmpty {
            lista.append(outraAtividade)
        }
        return lista.isEmpty ? "—" : lista.joined(separator: ", ") + "."
    }

    var periodoFormatado: String {
        "\(DateFormatter.diaMes.string(from: dataIda)) - \(DateFormatter.diaMes.string(from: dataVolta))"
    }
}
