//
//  ChecklistViewModel.swift
//
//  Created by Alana Queiroz on 26/03/26.
//

import Foundation
import FoundationModels
import PostHog

@Observable
class ChecklistViewModel {

    // MARK: - Input
    var destinoSelecionado: String = ""
    var dataIda: Date = Date()
    var dataVolta: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    var tipoViagem: String = ""
    var atividades: String = ""
    var numCriancas: Int = 0
    var numBebes: Int = 0

    func configurar(com viagem: Viagem) {
        destinoSelecionado = viagem.destino
        dataIda            = viagem.dataIda
        dataVolta          = viagem.dataVolta
        tipoViagem         = viagem.tipoViagem.rawValue
        atividades         = viagem.resumoAtividades
        numCriancas        = viagem.numCriancas
        numBebes           = viagem.numBebes
    }

    // MARK: - Weather display
    var tempMin: Double? = nil
    var tempMax: Double? = nil
    var condicaoClima: String = ""
    var estacao: String = ""

    // MARK: - List
    var itens: [ItemMala] = []
    var carregando: Bool = false

    // MARK: - Computed

    var quantidadeDias: Int {
        max(1, Calendar.current.dateComponents([.day], from: dataIda, to: dataVolta).day ?? 1)
    }

    var itensMarcados: Int { itens.filter { $0.estaMarcado }.count }
    var totalItens: Int { itens.count }

    var periodoFormatado: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "dd/MM"
        let fmtAno = DateFormatter()
        fmtAno.dateFormat = "yyyy"
        return "\(fmt.string(from: dataIda)) - \(fmt.string(from: dataVolta)), \(fmtAno.string(from: dataVolta))."
    }

    // MARK: - Actions

    func toggleItem(id: UUID) {
        if let idx = itens.firstIndex(where: { $0.id == id }) {
            itens[idx].estaMarcado.toggle()
        }
    }

    func ajustarQuantidade(id: UUID, delta: Int) {
        if let idx = itens.firstIndex(where: { $0.id == id }) {
            itens[idx].quantidade = max(1, itens[idx].quantidade + delta)
        }
    }

    func adicionarItem(categoria: String, nome: String) {
        guard !nome.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        itens.append(ItemMala(nome: "\(categoria)#\(nome)"))
    }

    func removerItem(id: UUID) {
        itens.removeAll { $0.id == id }
    }

    // MARK: - Generate

    func gerarLista() async {
        guard !destinoSelecionado.isEmpty else { return }

        await MainActor.run {
            carregando = true
            itens = []
        }

        let dias = quantidadeDias

        let qtdCamisetas = min(dias + 1, 12)
        let qtdIntimas   = min(dias + 2, 20)
        let qtdMeias     = min(dias + 2, 15)
        let qtdCalcas    = max(1, Int(ceil(Double(dias) / 3.0)))
        let qtdPijamas   = max(1, Int(ceil(Double(dias) / 4.0)))

        var isoCode = await WeatherService.shared.buscarCodigoPais(destino: destinoSelecionado)
        var classificacao = "AMENO"
        var climaResumo   = ""

        do {
            let clima = try await WeatherService.shared.buscarClima(
                destino: destinoSelecionado,
                dataInicio: dataIda,
                quantidadeDias: dias
            )
            await MainActor.run {
                tempMin       = clima.tempMin
                tempMax       = clima.tempMax
                condicaoClima = clima.condicaoDescricao
                estacao       = clima.estacao
            }
            classificacao = clima.classificacao
            if !clima.isoCountryCode.isEmpty { isoCode = clima.isoCountryCode }
            climaResumo = "\(Int(clima.tempMin))°C a \(Int(clima.tempMax))°C, \(clima.estacao), \(clima.condicaoDescricao)"
        } catch {
            print("🌤 WeatherKit ERRO: \(error)")
            print("🌤 Tipo do erro: \(type(of: error))")
            PostHogSDK.shared.capture("trip_weather_fetch_failed", properties: [
                "destination": destinoSelecionado,
                "error": error.localizedDescription
            ])
            let mes = Calendar.current.component(.month, from: dataIda)
            let hemisferioSul = ["BR","AR","CL","AU","NZ","ZA","UY","PY","BO","PE"].contains(isoCode.uppercased())
            let estacaoEstimada: String
            if hemisferioSul {
                switch mes {
                case 12,1,2: estacaoEstimada = "Summer"
                case 3,4,5:  estacaoEstimada = "Fall"
                case 6,7,8:  estacaoEstimada = "Winter"
                default:      estacaoEstimada = "Spring"
                }
            } else {
                switch mes {
                case 12,1,2: estacaoEstimada = "Winter"
                case 3,4,5:  estacaoEstimada = "Spring"
                case 6,7,8:  estacaoEstimada = "Summer"
                default:      estacaoEstimada = "Fall"
                }
            }
            await MainActor.run { estacao = estacaoEstimada }
            let fmt = DateFormatter()
            fmt.dateFormat = "MMMM"
            climaResumo = "\(fmt.string(from: dataIda))"
        }

        let foraDoBrasil = isoCode.uppercased() != "BR" && !isoCode.isEmpty


        // Clothing
        var linhasBase: [String] = [
            "Clothing#\(qtdCamisetas) T-shirts",
            "Clothing#\(qtdIntimas) Underwear",
            "Clothing#\(qtdMeias) Socks",
            "Clothing#\(qtdCalcas) Pants",
            "Clothing#\(qtdPijamas) Pajamas"
        ]

        // Weather extras
        switch classificacao {
        case "FRIO":
            linhasBase += [
                "Clothing#1 Heavy coat",
                "Clothing#1 Gloves",
                "Clothing#1 Scarf",
                "Clothing#1 Beanie",
                "Footwear#1 Waterproof boots"
            ]
        case "QUENTE":
            linhasBase += [
                "Clothing#1 Cap",
                "Clothing#2 Swimwear",
                "Toiletries#Sunscreen SPF 50+"
            ]
        default:
            linhasBase.append("Clothing#1 Light jacket")
        }

        // Footwear
        linhasBase.append("Footwear#1 Comfortable sneakers")

        // Documents
        if foraDoBrasil {
            linhasBase += [
                "Documents#Passport",
                "Documents#Travel insurance",
                "Documents#Hotel confirmation",
                "Documents#Flight tickets",
                "Documents#Credit/debit cards",
                "Documents#Cash",
                "Documents#Visa (if required)"
            ]
        } else {
            linhasBase += [
                "Documents#ID / Driver's license",
                "Documents#Flight tickets",
                "Documents#Reservations",
                "Documents#Credit/debit cards",
                "Documents#Cash"
            ]
        }

        // Toiletries
        linhasBase += [
            "Toiletries#Toothbrush",
            "Toiletries#Toothpaste",
            "Toiletries#Shampoo",
            "Toiletries#Conditioner",
            "Toiletries#Body wash",
            "Toiletries#Deodorant",
            "Toiletries#Perfume",
            "Toiletries#Hairbrush",
            "Toiletries#Razor",
            "Toiletries#Wet wipes"
        ]

        // Health & Meds
        linhasBase += [
            "Health & Meds#Painkillers",
            "Health & Meds#Antihistamine",
            "Health & Meds#Cold medicine",
            "Health & Meds#Band-aids",
            "Health & Meds#Hand sanitizer",
            "Health & Meds#Insect repellent"
        ]

        // Electronics
        linhasBase += [
            "Electronics#Phone",
            "Electronics#Phone charger",
            "Electronics#Earphones",
            "Electronics#Power bank",
            "Electronics#Travel adapter"
        ]

        // Kids (ages 2–12)
        if numCriancas > 0 {
            linhasBase += [
                "Kids#\(numCriancas) Kids' pajamas",
                "Kids#Extra clothes for the kids",
                "Kids#Kids' sunscreen",
                "Kids#Children's medicine (fever, pain)",
                "Kids#Kids' backpack",
                "Kids#Entertainment (tablet, books)"
            ]
        }

        // Baby (ages 0–2)
        if numBebes > 0 {
            let diapers = numBebes * dias * 6
            linhasBase += [
                "Baby#\(diapers) Diapers",
                "Baby#Diaper rash cream",
                "Baby#Baby wet wipes",
                "Baby#Baby bottle",
                "Baby#Baby formula",
                "Baby#Thermometer",
                "Baby#Extra baby clothes",
                "Baby#Pacifier"
            ]
        }

        //  todos os itens base
        let itensBase = linhasBase.map { linha -> ItemMala in
            var item = ItemMala(nome: linha)
            let words = item.displayNome.split(separator: " ", maxSplits: 1)
            if let first = words.first, let qty = Int(first) {
                item.quantidade = max(1, qty)
            }
            return item
        }

        let instrucaoIA = """
        You are a travel assistant. Generate ONLY specific extra items for the trip below that are NOT common clothing, documents, basic toiletries, basic electronics, or basic medicine — those are already on the list.

        TRIP: \(destinoSelecionado) — \(dias) days — \(climaResumo)
        TYPE: \(tipoViagem.isEmpty ? "Leisure" : tipoViagem)
        ACTIVITIES: \(atividades.isEmpty ? "None specified" : atividades)

        Examples: specific sports gear, special adapters, destination-specific cultural items.
        Maximum 6 extra items. If nothing relevant, reply only: NONE

        MANDATORY FORMAT — ONE ITEM PER LINE:
        Category#ItemName
        ALLOWED CATEGORIES: Clothing, Footwear, Toiletries, Health & Meds, Electronics
        FORBIDDEN: markdown, emojis, commas between items, explanatory text
        """

        var itensExtras: [ItemMala] = []
        do {
            let session = LanguageModelSession(instructions: instrucaoIA)
            let response = try await session.respond(to: "Extra items for \(destinoSelecionado).")

            if !response.content.uppercased().contains("NONE") {
                itensExtras = response.content
                    .components(separatedBy: .newlines)
                    .flatMap { $0.components(separatedBy: ",") }
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { linha in
                        guard !linha.isEmpty, linha.contains("#"),
                              let primeiro = linha.first else { return false }
                        return primeiro.isUppercase
                    }
                    .map { linha -> ItemMala in
                        var item = ItemMala(nome: linha)
                        let words = item.displayNome.split(separator: " ", maxSplits: 1)
                        if let first = words.first, let qty = Int(first) {
                            item.quantidade = max(1, qty)
                        }
                        return item
                    }
            }
        } catch {
            PostHogSDK.shared.capture("trip_ai_generation_failed", properties: [
                "destination": destinoSelecionado,
                "error": error.localizedDescription
            ])
        }

        await MainActor.run {
            itens = itensBase + itensExtras
            carregando = false
        }
        PostHogSDK.shared.capture("trip_list_generated", properties: [
            "destination": destinoSelecionado,
            "days": dias,
            "items_count": itensBase.count + itensExtras.count,
            "ai_extras_count": itensExtras.count
        ])
    }
}
