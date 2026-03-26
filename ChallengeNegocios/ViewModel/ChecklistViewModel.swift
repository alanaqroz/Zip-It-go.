//
//  ChecklistViewModel.swift
//  ChallengeNegocios
//
//  Created by Alana Queiroz on 25/03/26.
//

import Foundation
import FoundationModels

@Observable
class ChecklistViewModel {

    // MARK: - Input
    var destinoSelecionado: String = ""
    var dataIda: Date = Date()
    var dataVolta: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

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

    func adicionarItem(categoria: String, nome: String) {
        guard !nome.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        itens.append(ItemMala(nome: "\(categoria)#\(nome)"))
    }

    // MARK: - Generate

    func gerarLista() async {
        guard !destinoSelecionado.isEmpty else { return }

        await MainActor.run {
            carregando = true
            itens = []
        }

        let dias = quantidadeDias

        // ── 1. Quantidades de roupa pré-calculadas no Swift ──────────────
        let qtdCamisetas = min(dias + 1, 12)
        let qtdIntimas   = min(dias + 2, 20)
        let qtdMeias     = min(dias + 2, 15)
        let qtdCalcas    = max(1, Int(ceil(Double(dias) / 3.0)))
        let qtdPijamas   = max(1, Int(ceil(Double(dias) / 4.0)))

        // ── 2. Detecção de país (geocoder — muito confiável) ─────────────
        var isoCode = await WeatherService.shared.buscarCodigoPais(destino: destinoSelecionado)

        // ── 3. Clima real via WeatherKit ──────────────────────────────────
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
            climaResumo = "\(clima.classificacao) — \(Int(clima.tempMin))°C a \(Int(clima.tempMax))°C, \(clima.estacao), \(clima.condicaoDescricao)"
        } catch {
            let fmt = DateFormatter()
            fmt.dateFormat = "MMMM"
            climaResumo = "Mês: \(fmt.string(from: dataIda)) (clima estimado)"
        }

        let foraDoBrasil = isoCode.uppercased() != "BR" && !isoCode.isEmpty

        // ── 4. Extras de clima já determinados pelo WeatherKit ────────────
        let extrasClima: String
        switch classificacao {
        case "FRIO":
            extrasClima = """
            Clothing#1 Casaco pesado
            Clothing#1 Luvas
            Clothing#1 Cachecol
            Clothing#1 Gorro
            Footwear#1 Bota impermeável
            """
        case "QUENTE":
            extrasClima = """
            Clothing#1 Boné
            Clothing#2 Roupas de banho
            Toiletries#Protetor solar FPS 50+
            """
        default: // AMENO
            extrasClima = "Clothing#1 Casaco leve"
        }

        // ── 5. Documentos baseados no país real ───────────────────────────
        let documentos: String
        if foraDoBrasil {
            documentos = """
            Documents#Passaporte
            Documents#Seguro viagem
            Documents#Comprovante de hospedagem
            Documents#Passagens
            Documents#Cartões
            Documents#Dinheiro
            Documents#Visto (se necessário)
            """
        } else {
            documentos = """
            Documents#RG ou CNH
            Documents#Passagens
            Documents#Reservas
            Documents#Cartões
            Documents#Dinheiro
            """
        }

        // ── 6. Prompt sem regras de cálculo — tudo já vem pronto ─────────
        let instrucaoIA = """
        Você é um gerador de checklist de mala de viagem.

        FORMATO OBRIGATÓRIO — UM ITEM POR LINHA — NUNCA use vírgulas entre itens:
        Categoria#N NomeDoItem    (com quantidade, ex: Clothing#3 Camisetas)
        Categoria#NomeDoItem      (sem quantidade, ex: Documents#Passaporte)

        CATEGORIAS: Documents, Clothing, Footwear, Toiletries, Health & Meds, Electronics
        PROIBIDO: títulos, markdown (**), emojis, vírgulas entre itens, texto extra

        VIAGEM: \(destinoSelecionado) — \(dias) dias — \(climaResumo)

        INCLUA EXATAMENTE ESTES ITENS (copie linha por linha, sem alterar):
        Clothing#\(qtdCamisetas) Camisetas
        Clothing#\(qtdIntimas) Roupas íntimas
        Clothing#\(qtdMeias) Meias
        Clothing#\(qtdCalcas) Calças
        Clothing#\(qtdPijamas) Pijamas
        \(extrasClima)
        \(documentos)

        ALÉM DISSO, gere itens adequados ao destino e clima para:
        - Footwear: 1 tênis confortável (calçados de clima já incluídos acima)
        - Toiletries: escova de dentes, pasta de dentes, shampoo, condicionador, sabonete, desodorante, perfume, escova de cabelo, lâmina de barbear, lenços (itens de clima já incluídos acima)
        - Health & Meds: analgésicos, antialérgico, remédio para gripe, curativo, álcool em gel, repelente
        - Electronics: celular, carregadores, fone de ouvido, power bank, adaptador de tomada

        Gere a lista COMPLETA agora.
        """

        do {
            let session = LanguageModelSession(instructions: instrucaoIA)
            let response = try await session.respond(to: "Gere a lista para \(destinoSelecionado).")

            let linhas = response.content
                .components(separatedBy: .newlines)
                .flatMap { $0.components(separatedBy: ",") }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && $0.contains("#") }

            await MainActor.run {
                itens = linhas.isEmpty
                    ? [ItemMala(nome: "Erro#Tente gerar novamente")]
                    : linhas.map { ItemMala(nome: $0) }
                carregando = false
            }
        } catch {
            await MainActor.run { carregando = false }
        }
    }
}
