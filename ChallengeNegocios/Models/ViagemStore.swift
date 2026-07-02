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

    /// Fila serial dedicada à persistência. Mantém a ordem das gravações
    /// sem bloquear a main thread com encode do JSON + escrita no UserDefaults.
    private let filaPersistencia = DispatchQueue(
        label: "com.zipit.viagemstore.persistencia",
        qos: .utility
    )

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

    /// Faz um snapshot do estado atual (na main thread, onde `viagens` é lido)
    /// e delega o trabalho pesado (encode + escrita em disco) para uma fila
    /// em background, evitando travar a UI a cada alteração.
    private func salvar() {
        let snapshot = viagens
        filaPersistencia.async { [chave] in
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            UserDefaults.standard.set(data, forKey: chave)
        }
    }

    private func carregar() {
        guard
            let data  = UserDefaults.standard.data(forKey: chave),
            let lista = try? JSONDecoder().decode([Viagem].self, from: data)
        else { return }
        viagens = lista
    }
}
