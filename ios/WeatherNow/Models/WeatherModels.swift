import Foundation

enum WeatherUnit: String, CaseIterable, Identifiable {
    case metric
    case imperial

    var id: String { rawValue }

    var label: String {
        switch self {
        case .metric:
            return "C"
        case .imperial:
            return "F"
        }
    }
}

struct WeatherResponse: Decodable {
    let source: String
    let location: WeatherLocation
    let units: WeatherUnits
    let current: CurrentWeather
    let hourly: [HourlyForecast]
    let daily: [DailyForecast]
}

struct WeatherLocation: Decodable {
    let name: String
    let admin1: String?
    let country: String?
    let latitude: Double
    let longitude: Double
    let timezone: String?

    var displayName: String {
        [name, admin1, country]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}

struct WeatherUnits: Decodable {
    let temperature: String
    let windSpeed: String
    let precipitation: String
}

struct CurrentWeather: Decodable {
    let time: String?
    let temperature: Double?
    let apparentTemperature: Double?
    let humidity: Double?
    let precipitation: Double?
    let windSpeed: Double?
    let summary: String
    let icon: String
}

struct HourlyForecast: Decodable, Identifiable {
    let time: String
    let temperature: Double?
    let precipitationProbability: Double?
    let summary: String
    let icon: String

    var id: String { time }
}

struct DailyForecast: Decodable, Identifiable {
    let date: String
    let temperatureMax: Double?
    let temperatureMin: Double?
    let precipitationProbability: Double?
    let summary: String
    let icon: String

    var id: String { date }
}
