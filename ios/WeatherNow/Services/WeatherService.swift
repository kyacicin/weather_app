import Foundation

struct WeatherService {
    var baseURL = URL(string: "http://localhost:5050")!

    func weather(city: String, unit: WeatherUnit) async throws -> WeatherResponse {
        try await requestWeather(queryItems: [
            URLQueryItem(name: "city", value: city),
            URLQueryItem(name: "unit", value: unit.rawValue)
        ])
    }

    func weather(latitude: Double, longitude: Double, unit: WeatherUnit) async throws -> WeatherResponse {
        try await requestWeather(queryItems: [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "label", value: "Current location"),
            URLQueryItem(name: "unit", value: unit.rawValue)
        ])
    }

    private func requestWeather(queryItems: [URLQueryItem]) async throws -> WeatherResponse {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("api/weather"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw WeatherServiceError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherServiceError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let serverError = try? JSONDecoder().decode(ServerError.self, from: data)
            throw WeatherServiceError.server(serverError?.error ?? "Weather request failed.")
        }

        return try JSONDecoder().decode(WeatherResponse.self, from: data)
    }
}

private struct ServerError: Decodable {
    let error: String
}

enum WeatherServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The weather API URL is invalid."
        case .invalidResponse:
            return "The weather API returned an invalid response."
        case .server(let message):
            return message
        }
    }
}
