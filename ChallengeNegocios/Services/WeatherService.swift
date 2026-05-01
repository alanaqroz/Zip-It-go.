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

        // 2. Verifica se a viagem está dentro da janela do WeatherKit (~10 dias)
        let diasAteViagem = Calendar.current.dateComponents([.day], from: Date(), to: dataInicio).day ?? 0
        guard diasAteViagem <= 9 else {
            throw WeatherServiceError.semDados
        }

        // 3. Normaliza para início do dia (WeatherKit rejeita timestamps com hora exata)
        let cal = Calendar.current
        let inicioDia = cal.startOfDay(for: dataInicio)
        let dataFim   = cal.startOfDay(
            for: cal.date(byAdding: .day, value: max(quantidadeDias, 1), to: inicioDia) ?? inicioDia
        )

        print("🌤 WeatherKit buscando: \(destino) | \(inicioDia) → \(dataFim) | lat: \(latitude)")

        // 4. Previsão diária via WeatherKit
        let previsao = try await kit.weather(
            for: location,
            including: .daily(startDate: inicioDia, endDate: dataFim)
        )

        let dias = previsao.forecast
        guard !dias.isEmpty else { throw WeatherServiceError.semDados }

        // 5. Temperaturas
        let maximas = dias.map { $0.highTemperature.converted(to: .celsius).value }
        let minimas  = dias.map { $0.lowTemperature.converted(to: .celsius).value }
        let medias   = zip(maximas, minimas).map { ($0 + $1) / 2.0 }

        let tempMin  = minimas.min() ?? 0
        let tempMax  = maximas.max() ?? 0
        let mediaGeral = medias.reduce(0, +) / Double(medias.count)

        // 6. Condição dominante — a que aparece mais dias no período
        let condicoes = dias
            .map { traduzirCondicao($0.condition) }
            .reduce(into: [:]) { counts, c in counts[c, default: 0] += 1 }
            .max(by: { $0.value < $1.value })?.key ?? ""

        // 7. Estação com base no mês de início e hemisfério
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
        case 12, 1, 2:  return hemisferioSul ? "Summer" : "Winter"
        case 3, 4, 5:   return hemisferioSul ? "Fall"   : "Spring"
        case 6, 7, 8:   return hemisferioSul ? "Winter" : "Summer"
        case 9, 10, 11: return hemisferioSul ? "Spring" : "Fall"
        default:         return ""
        }
    }

    private func traduzirCondicao(_ condition: WeatherCondition) -> String {
        switch condition {
        case .clear:                    return "clear"
        case .mostlyClear:              return "mostly clear"
        case .partlyCloudy:             return "partly cloudy"
        case .mostlyCloudy:             return "mostly cloudy"
        case .cloudy:                   return "cloudy"
        case .foggy:                    return "foggy"
        case .haze:                     return "hazy"
        case .drizzle:                  return "drizzle"
        case .rain:                     return "rain"
        case .heavyRain:                return "heavy rain"
        case .isolatedThunderstorms:    return "isolated thunderstorms"
        case .scatteredThunderstorms:   return "scattered thunderstorms"
        case .thunderstorms:            return "thunderstorms"
        case .snow:                     return "snow"
        case .heavySnow:                return "heavy snow"
        case .flurries:                 return "snow flurries"
        case .blowingSnow:              return "blowing snow"
        case .blizzard:                 return "blizzard"
        case .sleet:                    return "sleet"
        case .freezingRain:             return "freezing rain"
        case .hot:                      return "very hot"
        case .windy:                    return "windy"
        case .breezy:                   return "breezy"
        case .sunShowers:               return "sun showers"
        case .tropicalStorm:            return "tropical storm"
        case .hurricane:                return "hurricane"
        default:                        return "variable"
        }
    }
}
