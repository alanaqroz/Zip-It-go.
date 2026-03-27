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

    var categoria: String {
        nome.components(separatedBy: "#").first ?? "Geral"
    }

    var displayNome: String {
        let parts = nome.components(separatedBy: "#")
        guard parts.count > 1 else { return nome }
        return parts[1...].joined(separator: "#").trimmingCharacters(in: .whitespaces)
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
