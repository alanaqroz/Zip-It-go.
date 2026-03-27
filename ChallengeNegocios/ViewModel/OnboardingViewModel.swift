//
//  OnboardingViewModel.swift
//  ChallengeNegocios
//
//  Estado compartilhado entre todas as telas do onboarding (Telas 1–4).
//  A navegação usa um array de Int como caminho (etapas visitadas).
//
//  Fluxo:
//    [] → Tela 1 (raiz)
//    [2] → Tela 2
//    [2, 3] → Tela 3
//    [2, 3, 4] → Tela 4
//

import Foundation

@Observable
class OnboardingViewModel {
    var viagem: Viagem = Viagem()
    var etapas: [Int] = []

    func avancar(para etapa: Int) {
        etapas.append(etapa)
    }

    func editarEtapa(_ etapa: Int) {
        if etapa <= 1 {
            etapas = []
        } else {
            etapas = Array(2...etapa)
        }
    }

    func reiniciar() {
        viagem = Viagem()
        etapas = []
    }
}
