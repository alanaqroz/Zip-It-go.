//
//  ItemMala.swift
//  ChallengeNegocios
//
//  Created by Alana Queiroz on 25/03/26.
//

import SwiftUI

struct ItemMala: Identifiable, Codable {
    var id: UUID = UUID()
    var nome: String
    var estaMarcado: Bool = false
    var quantidade: Int = 1

    var categoria: String {
        nome.components(separatedBy: "#").first ?? "Geral"
    }

    var displayNome: String {
        let parts = nome.components(separatedBy: "#")
        guard parts.count > 1 else { return nome }
        return parts[1...].joined(separator: "#").trimmingCharacters(in: .whitespaces)
    }

    var nomeApenas: String {
        let words = displayNome.split(separator: " ", maxSplits: 1)
        if let first = words.first, Int(first) != nil {
            return words.count > 1 ? String(words[1]) : displayNome
        }
        return displayNome
    }
}

// MARK: - Checkbox Style

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? .blue : .secondary)
                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}
