//
//  ViagemStore.swift
//  ChallengeNegocios
//
//  Created by Alana Queiroz on 26/03/26.
//

import Foundation

@Observable
class ViagemStore {
    var viagens: [Viagem] = []

    private let chave = "viagens_salvas"

    init() {
        carregar()
    }

    // MARK: - CRUD

    func adicionar(_ viagem: Viagem) {
        viagens.insert(viagem, at: 0)
        salvar()
    }

    func atualizar(_ viagem: Viagem) {
        guard let idx = viagens.firstIndex(where: { $0.id == viagem.id }) else { return }
        viagens[idx] = viagem
        salvar()
    }

    func remover(id: UUID) {
        viagens.removeAll { $0.id == id }
        salvar()
    }

    // MARK: - Persistência

    private func salvar() {
        guard let data = try? JSONEncoder().encode(viagens) else { return }
        UserDefaults.standard.set(data, forKey: chave)
    }

    private func carregar() {
        guard
            let data  = UserDefaults.standard.data(forKey: chave),
            let lista = try? JSONDecoder().decode([Viagem].self, from: data)
        else { return }
        viagens = lista
    }
}
