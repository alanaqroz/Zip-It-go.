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
    var numAdultos: Int = 1
    var numCriancas: Int = 0
    var numBebes: Int = 0
    var outraAtividade: String = ""

    func configurar(com viagem: Viagem) {
        destinoSelecionado = viagem.destino
        dataIda            = viagem.dataIda
        dataVolta          = viagem.dataVolta
        tipoViagem         = viagem.tipoViagem.rawValue
        atividades         = viagem.resumoAtividades
        numAdultos         = viagem.numAdultos
        numCriancas        = viagem.numCriancas
        numBebes           = viagem.numBebes
        outraAtividade     = viagem.outraAtividade
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
            // Antes: estimava a estação com uma lista fixa de 10 países pra
            // decidir hemisfério, sem latitude — nem cobria a maioria dos
            // países do hemisfério sul, nem captava que um país grande (ex:
            // Brasil) cruza zonas climáticas bem diferentes. Agora reaproveita
            // a mesma lógica baseada em latitude/trópicos do WeatherService.
            let estacaoEstimada = await WeatherService.shared.estimarEstacao(
                destino: destinoSelecionado,
                data: dataIda
            )
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

        // Documents — quantidade de passaportes = número de adultos + crianças (bebês usam o mesmo)
        let totalViajantesComDoc = numAdultos + numCriancas + numBebes
        if foraDoBrasil {
            linhasBase += [
                "Documents#\(totalViajantesComDoc) Passport\(totalViajantesComDoc > 1 ? "s" : "")",
                "Documents#Travel insurance",
                "Documents#Hotel confirmation",
                "Documents#Flight tickets",
                "Documents#Credit/debit cards",
                "Documents#Cash",
                "Documents#Visa (if required)"
            ]
        } else {
            linhasBase += [
                "Documents#\(totalViajantesComDoc) ID / Driver's license",
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

        // Kids (ages 2–12) — mesma lógica de quantidade dos adultos, multiplicada por criança
        if numCriancas > 0 {
            let kTshirts  = numCriancas * min(dias + 1, 10)
            let kUnderwear = numCriancas * min(dias + 2, 15)
            let kSocks    = numCriancas * min(dias + 2, 12)
            let kPants    = numCriancas * max(1, Int(ceil(Double(dias) / 3.0)))
            let kPajamas  = numCriancas * max(1, Int(ceil(Double(dias) / 3.0)))

            linhasBase += [
                "Kids#\(kTshirts) Kids' T-shirts",
                "Kids#\(kUnderwear) Kids' underwear",
                "Kids#\(kSocks) Kids' socks",
                "Kids#\(kPants) Kids' pants",
                "Kids#\(kPajamas) Kids' pajamas",
                "Kids#\(numCriancas) Kids' sneakers",
                "Kids#Kids' sunscreen SPF 50+",
                "Kids#Children's medicine (fever, pain)",
                "Kids#Kids' backpack",
                "Kids#Entertainment (tablet, books)"
            ]
            // Roupas de frio para crianças se necessário
            if classificacao == "FRIO" {
                linhasBase += [
                    "Kids#\(numCriancas) Kids' coat",
                    "Kids#\(numCriancas) Kids' gloves",
                    "Kids#\(numCriancas) Kids' beanie"
                ]
            }
        }

        // Baby (ages 0–2) — roupas calculadas por dias + itens essenciais
        if numBebes > 0 {
            let diapers    = numBebes * dias * 6
            let bOnesies   = numBebes * min(dias * 2, 14)   // ~2 macacões por dia
            let bPajamas   = numBebes * max(1, Int(ceil(Double(dias) / 2.0)))
            let bSocks     = numBebes * min(dias + 2, 10)

            linhasBase += [
                "Baby#\(diapers) Diapers",
                "Baby#\(bOnesies) Baby onesies",
                "Baby#\(bPajamas) Baby pajamas",
                "Baby#\(bSocks) Baby socks",
                "Baby#\(numBebes) Baby shoes",
                "Baby#Diaper rash cream",
                "Baby#Baby wet wipes",
                "Baby#Baby bottle",
                "Baby#Baby formula",
                "Baby#Thermometer",
                "Baby#Pacifier"
            ]
            if classificacao == "FRIO" {
                linhasBase += [
                    "Baby#\(numBebes) Baby snowsuit",
                    "Baby#\(numBebes) Baby mittens"
                ]
            }
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

        // Resumo dos viajantes para o prompt
        var viajantesResumo = "\(numAdultos) adult\(numAdultos > 1 ? "s" : "")"
        if numCriancas > 0 { viajantesResumo += ", \(numCriancas) kid\(numCriancas > 1 ? "s" : "")" }
        if numBebes    > 0 { viajantesResumo += ", \(numBebes) baby\(numBebes > 1 ? "/babies" : "")" }

        // Categorias já incluídas na lista base — a IA não deve repetir itens dessas categorias
        let categoriasBase = Array(Set(linhasBase.compactMap { $0.split(separator: "#").first.map(String.init) }))
            .sorted().joined(separator: ", ")

        // Atividade extra digitada pelo usuário (campo livre)
        let atividadeExtra = outraAtividade.trimmingCharacters(in: .whitespaces)

        let instrucaoIA = """
        You are an expert travel packing assistant. Your job is to suggest ONLY items that are truly missing from the list below.

        TRIP DETAILS:
        - Destination: \(destinoSelecionado)
        - Duration: \(dias) days
        - Weather: \(climaResumo.isEmpty ? "unknown" : climaResumo)
        - Trip type: \(tipoViagem.isEmpty ? "Leisure" : tipoViagem)
        - Travelers: \(viajantesResumo)
        - Planned activities: \(atividades.isEmpty ? "None specified" : atividades)\(atividadeExtra.isEmpty ? "" : ", \(atividadeExtra)")

        ALREADY INCLUDED IN THE LIST (do NOT suggest items from these categories):
        \(categoriasBase)

        YOUR TASK: Suggest destination-specific or activity-specific items that are NOT already covered above.
        Focus on: special gear for activities, local cultural necessities, climate-specific items beyond basic clothing.
        If there is truly nothing to add, reply only: NONE

        MANDATORY FORMAT — ONE ITEM PER LINE:
        Category#ItemName
        ALLOWED CATEGORIES: Clothing, Footwear, Toiletries, Health & Meds, Electronics
        Maximum 6 items. No markdown, no emojis, no explanations.
        """

        var itensExtras: [ItemMala] = []
        do {
            let session = LanguageModelSession(instructions: instrucaoIA)
            let query = "Suggest extra packing items for a \(dias)-day \(tipoViagem.isEmpty ? "leisure" : tipoViagem.lowercased()) trip to \(destinoSelecionado) (\(climaResumo.isEmpty ? "weather unknown" : climaResumo)) for \(viajantesResumo)\(atividades.isEmpty ? "" : ", activities: \(atividades)")."
            let response = try await session.respond(to: query)

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
