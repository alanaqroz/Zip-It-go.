//
//  WeatherService.swift
//  ChallengeNegocios
//
//  Created by Alana Queiroz on 25/03/26.
//

import Foundation
import WeatherKit
import CoreLocation

// MARK: - Model

struct ClimaViagem {
    let tempMin: Double           // mínima do período (°C)
    let tempMax: Double           // máxima do período (°C)
    let temperaturaMedia: Double  // média das médias diárias (°C)
    let condicaoDescricao: String // condições em português
    let estacao: String           // Verão / Outono / Inverno / Primavera
    let isoCountryCode: String    // ex: "BR", "US", "FR"
    let fonteDados: String

    var estaForaDoBrasil: Bool { isoCountryCode.uppercased() != "BR" }

    /// "FRIO", "QUENTE" ou "AMENO" — sem texto extra
    var classificacao: String {
        switch temperaturaMedia {
        case ..<15:  return "FRIO"
        case 25...:  return "QUENTE"
        default:     return "AMENO"
        }
    }
}

// MARK: - Errors

enum WeatherServiceError: LocalizedError {
    case localNaoEncontrado
    case semDados

    var errorDescription: String? {
        switch self {
        case .localNaoEncontrado: return "Local não encontrado."
        case .semDados:           return "Nenhum dado climático disponível."
        }
    }
}

// MARK: - Service

actor WeatherService {
    static let shared = WeatherService()
    private let kit = WeatherKit.WeatherService.shared

    func buscarClima(
        destino: String,
        dataInicio: Date,
        quantidadeDias: Int
    ) async throws -> ClimaViagem {

        // 1. Geocodifica destino → coordenadas
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(destino)
        guard let placemark = placemarks.first, let location = placemark.location else {
            throw WeatherServiceError.localNaoEncontrado
        }

        let latitude = location.coordinate.latitude

        // 2. Intervalo de datas
        let dataFim = Calendar.current.date(
            byAdding: .day, value: max(quantidadeDias, 1), to: dataInicio
        ) ?? dataInicio

        // 3. Previsão diária via WeatherKit
        let previsao = try await kit.weather(
            for: location,
            including: .daily(startDate: dataInicio, endDate: dataFim)
        )

        let dias = previsao.forecast
        guard !dias.isEmpty else { throw WeatherServiceError.semDados }

        // 4. Temperaturas
        let maximas = dias.map { $0.highTemperature.converted(to: .celsius).value }
        let minimas  = dias.map { $0.lowTemperature.converted(to: .celsius).value }
        let medias   = zip(maximas, minimas).map { ($0 + $1) / 2.0 }

        let tempMin  = minimas.min() ?? 0
        let tempMax  = maximas.max() ?? 0
        let mediaGeral = medias.reduce(0, +) / Double(medias.count)

        // 5. Condições únicas em português
        let condicoes = Array(Set(dias.map { traduzirCondicao($0.condition) }))
            .prefix(3)
            .joined(separator: ", ")

        // 6. Estação com base no mês de início e hemisfério
        let mes = Calendar.current.component(.month, from: dataInicio)
        let estacao = detectarEstacao(mes: mes, latitude: latitude)

        let isoCountryCode = placemark.isoCountryCode ?? ""

        return ClimaViagem(
            tempMin: tempMin,
            tempMax: tempMax,
            temperaturaMedia: mediaGeral,
            condicaoDescricao: condicoes,
            estacao: estacao,
            isoCountryCode: isoCountryCode,
            fonteDados: "WeatherKit"
        )
    }

    /// Retorna o código ISO do país (ex: "BR") sem precisar buscar clima.
    func buscarCodigoPais(destino: String) async -> String {
        let geocoder = CLGeocoder()
        guard let placemarks = try? await geocoder.geocodeAddressString(destino),
              let code = placemarks.first?.isoCountryCode else { return "" }
        return code
    }

    // MARK: - Helpers

    private func detectarEstacao(mes: Int, latitude: Double) -> String {
        let hemisferioSul = latitude < 0
        switch mes {
        case 12, 1, 2:  return hemisferioSul ? "Verão"    : "Inverno"
        case 3, 4, 5:   return hemisferioSul ? "Outono"   : "Primavera"
        case 6, 7, 8:   return hemisferioSul ? "Inverno"  : "Verão"
        case 9, 10, 11: return hemisferioSul ? "Primavera": "Outono"
        default:         return ""
        }
    }

    private func traduzirCondicao(_ condition: WeatherCondition) -> String {
        switch condition {
        case .clear:                    return "céu limpo"
        case .mostlyClear:              return "predominantemente limpo"
        case .partlyCloudy:             return "parcialmente nublado"
        case .mostlyCloudy:             return "predominantemente nublado"
        case .cloudy:                   return "nublado"
        case .foggy:                    return "neblina"
        case .haze:                     return "névoa"
        case .drizzle:                  return "garoa"
        case .rain:                     return "chuva"
        case .heavyRain:                return "chuva intensa"
        case .isolatedThunderstorms:    return "trovoadas isoladas"
        case .scatteredThunderstorms:   return "trovoadas esparsas"
        case .thunderstorms:            return "tempestade"
        case .snow:                     return "neve"
        case .heavySnow:                return "neve intensa"
        case .flurries:                 return "rajadas de neve"
        case .blowingSnow:              return "neve com vento"
        case .blizzard:                 return "nevasca"
        case .sleet:                    return "granizo"
        case .freezingRain:             return "chuva congelante"
        case .hot:                      return "muito quente"
        case .windy:                    return "ventoso"
        case .breezy:                   return "brisa"
        case .sunShowers:               return "chuva com sol"
        case .tropicalStorm:            return "tempestade tropical"
        case .hurricane:                return "furacão"
        default:                        return "variável"
        }
    }
}
