//
//  OnboardingViewModel.swift
//  ChallengeNegocios
//
//  Created by Alana Queiroz on 26/03/26.
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
