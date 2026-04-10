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
                case 12,1,2: estacaoEstimada = "Verão"
                case 3,4,5:  estacaoEstimada = "Outono"
                case 6,7,8:  estacaoEstimada = "Inverno"
                default:      estacaoEstimada = "Primavera"
                }
            } else {
                switch mes {
                case 12,1,2: estacaoEstimada = "Inverno"
                case 3,4,5:  estacaoEstimada = "Primavera"
                case 6,7,8:  estacaoEstimada = "Verão"
                default:      estacaoEstimada = "Outono"
                }
            }
            await MainActor.run { estacao = estacaoEstimada }
            let fmt = DateFormatter()
            fmt.dateFormat = "MMMM"
            climaResumo = "mês \(fmt.string(from: dataIda))"
        }

        let foraDoBrasil = isoCode.uppercased() != "BR" && !isoCode.isEmpty


        // Clothing
        var linhasBase: [String] = [
            "Clothing#\(qtdCamisetas) Camisetas",
            "Clothing#\(qtdIntimas) Roupas íntimas",
            "Clothing#\(qtdMeias) Meias",
            "Clothing#\(qtdCalcas) Calças",
            "Clothing#\(qtdPijamas) Pijamas"
        ]

        // Extras de clima
        switch classificacao {
        case "FRIO":
            linhasBase += [
                "Clothing#1 Casaco pesado",
                "Clothing#1 Luvas",
                "Clothing#1 Cachecol",
                "Clothing#1 Gorro",
                "Footwear#1 Bota impermeável"
            ]
        case "QUENTE":
            linhasBase += [
                "Clothing#1 Boné",
                "Clothing#2 Roupas de banho",
                "Toiletries#Protetor solar FPS 50+"
            ]
        default:
            linhasBase.append("Clothing#1 Casaco leve")
        }

        // Footwear
        linhasBase.append("Footwear#1 Tênis confortável")

        // Documents
        if foraDoBrasil {
            linhasBase += [
                "Documents#Passaporte",
                "Documents#Seguro viagem",
                "Documents#Comprovante de hospedagem",
                "Documents#Passagens",
                "Documents#Cartões",
                "Documents#Dinheiro",
                "Documents#Visto (se necessário)"
            ]
        } else {
            linhasBase += [
                "Documents#RG ou CNH",
                "Documents#Passagens",
                "Documents#Reservas",
                "Documents#Cartões",
                "Documents#Dinheiro"
            ]
        }

        // Toiletries
        linhasBase += [
            "Toiletries#Escova de dentes",
            "Toiletries#Pasta de dentes",
            "Toiletries#Shampoo",
            "Toiletries#Condicionador",
            "Toiletries#Sabonete",
            "Toiletries#Desodorante",
            "Toiletries#Perfume",
            "Toiletries#Escova de cabelo",
            "Toiletries#Lâmina de barbear",
            "Toiletries#Lenços umedecidos"
        ]

        // Health & Meds
        linhasBase += [
            "Health & Meds#Analgésicos",
            "Health & Meds#Antialérgico",
            "Health & Meds#Remédio para gripe",
            "Health & Meds#Curativo",
            "Health & Meds#Álcool em gel",
            "Health & Meds#Repelente"
        ]

        // Electronics
        linhasBase += [
            "Electronics#Celular",
            "Electronics#Carregador de celular",
            "Electronics#Fone de ouvido",
            "Electronics#Power bank",
            "Electronics#Adaptador de tomada"
        ]

        // Kids — itens para crianças (2–12 anos)
        if numCriancas > 0 {
            linhasBase += [
                "Kids#\(numCriancas) Pijamas infantis",
                "Kids#Roupas extras para as crianças",
                "Kids#Protetor solar infantil",
                "Kids#Remédios infantis (febre, dor)",
                "Kids#Mochila infantil",
                "Kids#Entretenimento (tablet, livros)"
            ]
        }

        // Baby — itens para bebês (0–2 anos)
        if numBebes > 0 {
            let fraldas = numBebes * dias * 6   // ~6 fraldas/dia por bebê????????
            linhasBase += [
                "Baby#\(fraldas) Fraldas",
                "Baby#Pomada para assaduras",
                "Baby#Lenços umedecidos bebê",
                "Baby#Mamadeira",
                "Baby#Leite em pó",
                "Baby#Termômetro",
                "Baby#Roupas extras de bebê",
                "Baby#Chupeta"
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
        Você é um assistente de viagem. Gere APENAS itens extras específicos para a viagem abaixo que NÃO sejam roupas comuns, documentos, higiene básica, eletrônicos básicos ou remédios básicos — esses já estão na lista.

        VIAGEM: \(destinoSelecionado) — \(dias) dias — \(climaResumo)
        TIPO: \(tipoViagem.isEmpty ? "Lazer" : tipoViagem)
        ATIVIDADES: \(atividades.isEmpty ? "Nenhuma especificada" : atividades)

        Exemplos do que gerar: equipamentos de esporte específicos, adaptadores especiais, itens culturais do destino.
        Máximo 6 itens extras. Se não houver nada relevante, responda apenas: NENHUM

        FORMATO OBRIGATÓRIO — UM ITEM POR LINHA:
        Categoria#NomeDoItem
        CATEGORIAS PERMITIDAS: Clothing, Footwear, Toiletries, Health & Meds, Electronics
        PROIBIDO: markdown, emojis, vírgulas entre itens, texto explicativo
        """

        var itensExtras: [ItemMala] = []
        do {
            let session = LanguageModelSession(instructions: instrucaoIA)
            let response = try await session.respond(to: "Extras para \(destinoSelecionado).")

            if !response.content.uppercased().contains("NENHUM") {
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
