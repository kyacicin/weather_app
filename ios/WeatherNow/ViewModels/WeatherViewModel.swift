import Foundation

@MainActor
final class WeatherViewModel: ObservableObject {
    @Published var weather: WeatherResponse?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var unit: WeatherUnit = .metric

    private let service = WeatherService()
    private var lastLookup = Lookup.city("Almaty")

    func loadDefault() async {
        await search(city: "Almaty")
    }

    func search(city: String) async {
        let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedCity.count >= 2 else {
            errorMessage = "Enter at least 2 characters to search a city."
            return
        }

        lastLookup = .city(trimmedCity)
        await refresh()
    }

    func useLocation(latitude: Double, longitude: Double) async {
        lastLookup = .coordinates(latitude: latitude, longitude: longitude)
        await refresh()
    }

    func changeUnit(_ nextUnit: WeatherUnit) {
        unit = nextUnit
        Task {
            await refresh()
        }
    }

    func showError(_ message: String) {
        errorMessage = message
    }

    private func refresh() async {
        isLoading = true
        errorMessage = nil

        do {
            switch lastLookup {
            case .city(let city):
                weather = try await service.weather(city: city, unit: unit)
            case .coordinates(let latitude, let longitude):
                weather = try await service.weather(latitude: latitude, longitude: longitude, unit: unit)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

private enum Lookup {
    case city(String)
    case coordinates(latitude: Double, longitude: Double)
}
