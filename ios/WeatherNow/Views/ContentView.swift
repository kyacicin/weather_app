import SwiftUI

private enum WeatherTab: CaseIterable {
    case home
    case details
    case saved
    case profile

    var title: String {
        switch self {
        case .home:
            return "Home"
        case .details:
            return "Stats"
        case .saved:
            return "Saved"
        case .profile:
            return "Profile"
        }
    }

    var symbol: String {
        switch self {
        case .home:
            return "house.fill"
        case .details:
            return "chart.line.uptrend.xyaxis"
        case .saved:
            return "bookmark.fill"
        case .profile:
            return "person.fill"
        }
    }
}

struct ContentView: View {
    @StateObject private var model = WeatherViewModel()
    @StateObject private var locationProvider = LocationProvider()
    @State private var city = "Almaty"
    @State private var selectedTab: WeatherTab = .home

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if model.isLoading {
                    loadingView
                } else if let error = model.errorMessage {
                    errorView(error)
                } else if let weather = model.weather {
                    ScrollView(showsIndicators: false) {
                        if selectedTab == .details {
                            detailScreen(weather)
                                .padding(.horizontal, 22)
                                .padding(.top, 18)
                                .padding(.bottom, 112)
                        } else {
                            homeScreen(weather)
                                .padding(.horizontal, 22)
                                .padding(.top, 16)
                                .padding(.bottom, 112)
                        }
                    }
                }

                bottomBar
            }
        }
        .task {
            locationProvider.onLocation = { coordinate in
                Task {
                    await model.useLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                }
            }
            locationProvider.onError = { message in
                model.showError(message)
            }
            await model.loadDefault()
        }
    }

    private var background: some View {
        Group {
            if selectedTab == .details {
                LinearGradient(
                    colors: [Color(hex: 0xF8F8FF), Color(hex: 0xFFFFFF)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                LinearGradient(
                    colors: [Color(hex: 0xD94F94), Color(hex: 0xA36DE0), Color(hex: 0x5E8BE8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    private func homeScreen(_ weather: WeatherResponse) -> some View {
        VStack(spacing: 18) {
            homeHeader

            FigmaCloudIllustration(mode: .home)
                .frame(height: 210)
                .padding(.top, 8)

            homeForecastCard(weather)

            statsPanel(weather)
        }
    }

    private var homeHeader: some View {
        VStack(spacing: 14) {
            HStack {
                Text("W.")
                    .font(.system(size: 24, weight: .black, design: .serif))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(.white.opacity(0.18), in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.75), lineWidth: 1))

                Spacer()

                unitToggle

                Button {
                    locationProvider.requestCurrentLocation()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.16), in: Circle())
                }
                .accessibilityLabel("Use current location")
            }

            searchField(tint: .white)
        }
    }

    private func homeForecastCard(_ weather: WeatherResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(weather.location.displayName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(hex: 0x242436))
                        .lineLimit(2)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(formatTemperatureNumber(weather.current.temperature))
                            .font(.system(size: 42, weight: .black))
                            .foregroundStyle(Color(hex: 0x111827))
                        Text(weather.units.temperature)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color(hex: 0x111827))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Text(weather.current.summary)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(hex: 0xD94F94))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color(hex: 0xFCE7F3), in: Capsule())

                    Text(formatTime(weather.current.time ?? ""))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 10) {
                miniPill("Today", value: formatTemperature(weather.current.temperature, unit: weather.units.temperature), color: Color(hex: 0xFFF4B8))
                miniPill("Feels", value: formatTemperature(weather.current.apparentTemperature, unit: weather.units.temperature), color: Color(hex: 0xE9D5FF))
            }

            Button {
                selectedTab = .details
            } label: {
                Text("VIEW STATS")
                    .font(.caption.weight(.black))
                    .tracking(0.7)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color(hex: 0x5A50D8), in: Capsule())
            }
        }
        .padding(22)
        .background(.white, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: Color.black.opacity(0.16), radius: 24, x: 0, y: 18)
    }

    private func statsPanel(_ weather: WeatherResponse) -> some View {
        VStack(spacing: 12) {
            statRow(symbol: "drop.fill", title: "Precipitation", value: "\(Int(weather.hourly.first?.precipitationProbability ?? 0))%")
            statRow(symbol: "humidity.fill", title: "Humidity", value: "\(Int(weather.current.humidity ?? 0))%")
            statRow(symbol: "wind", title: "Wind", value: "\(Int(weather.current.windSpeed ?? 0)) \(weather.units.windSpeed)")
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 18)
        .foregroundStyle(.white)
    }

    private func detailScreen(_ weather: WeatherResponse) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Button {
                    selectedTab = .home
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(hex: 0x222033))
                        .frame(width: 42, height: 42)
                        .background(.white, in: Circle())
                        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
                }

                Spacer()

                unitToggle
            }

            ZStack(alignment: .topTrailing) {
                FigmaCloudIllustration(mode: .detail)
                    .frame(height: 150)
                    .offset(x: 24, y: -18)

                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(weather.location.displayName)
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(Color(hex: 0x202033))
                            .lineLimit(2)

                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(formatTemperatureNumber(weather.current.temperature))
                                .font(.system(size: 58, weight: .black))
                                .foregroundStyle(Color(hex: 0x111827))
                            Text(weather.units.temperature)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color(hex: 0x111827))
                        }
                    }
                    .padding(.top, 92)

                    HStack(spacing: 10) {
                        metricChip(symbol: "cloud.rain.fill", value: "\(Int(weather.hourly.first?.precipitationProbability ?? 0))%", color: Color(hex: 0xEFF6FF))
                        metricChip(symbol: "thermometer.medium", value: formatTemperature(weather.current.apparentTemperature, unit: weather.units.temperature), color: Color(hex: 0xFCE7F3))
                        metricChip(symbol: "wind", value: "\(Int(weather.current.windSpeed ?? 0)) \(weather.units.windSpeed)", color: Color(hex: 0xF5F3FF))
                    }

                    todayCurve(weather)
                    hourlyForecast(weather)
                    weeklyForecast(weather)
                }
            }
        }
    }

    private func todayCurve(_ weather: WeatherResponse) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today")
                .font(.headline)
                .foregroundStyle(Color(hex: 0x202033))

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(hex: 0xFFF7D6))

                TemperatureCurve()
                    .stroke(Color(hex: 0xE9B710), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(height: 78)
                    .padding(.horizontal, 2)
                    .padding(.bottom, 22)

                HStack {
                    ForEach(Array(weather.hourly.prefix(4))) { hour in
                        VStack(spacing: 6) {
                            Text(formatTime(hour.time))
                                .font(.caption2)
                                .foregroundStyle(Color(hex: 0x8A7B29))
                            Text(formatTemperature(hour.temperature, unit: weather.units.temperature))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color(hex: 0x3F3512))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            .frame(height: 132)
        }
    }

    private func hourlyForecast(_ weather: WeatherResponse) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(Array(weather.hourly.prefix(5))) { hour in
                    VStack(spacing: 8) {
                        Text(hour.icon)
                            .font(.system(size: 30))
                        Text(formatTemperature(hour.temperature, unit: weather.units.temperature))
                            .font(.system(size: 18, weight: .black))
                            .foregroundStyle(Color(hex: 0x1F2433))
                        Text(formatTime(hour.time))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 78, height: 116)
                    .background(.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .shadow(color: Color.black.opacity(0.07), radius: 14, x: 0, y: 8)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func weeklyForecast(_ weather: WeatherResponse) -> some View {
        VStack(spacing: 14) {
            ForEach(Array(weather.daily.dropFirst().prefix(5))) { day in
                HStack(spacing: 14) {
                    Text(formatWeekday(day.date))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color(hex: 0x202033))
                        .frame(width: 86, alignment: .leading)

                    Text(day.icon)
                        .font(.title3)

                    Spacer()

                    Text(formatTemperature(day.temperatureMax, unit: weather.units.temperature))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(hex: 0x202033))

                    Text(formatTemperature(day.temperatureMin, unit: weather.units.temperature))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.top, 4)
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            ForEach(WeatherTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab == .home || tab == .details ? tab : selectedTab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 16, weight: .bold))
                        Text(tab.title)
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(selectedTab == tab ? Color(hex: 0xD94F94) : Color(hex: 0xC7C8D4))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .disabled(tab == .saved || tab == .profile)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .padding(.horizontal, 22)
        .padding(.bottom, 14)
        .shadow(color: Color.black.opacity(0.13), radius: 22, x: 0, y: 12)
    }

    private func searchField(tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(tint.opacity(0.82))

            TextField("Search city", text: $city)
                .submitLabel(.search)
                .foregroundStyle(.white)
                .textInputAutocapitalization(.words)
                .onSubmit {
                    Task {
                        await model.search(city: city)
                    }
                }

            Button {
                Task {
                    await model.search(city: city)
                }
            } label: {
                Text("Go")
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color(hex: 0x5A50D8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.white, in: Capsule())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.white.opacity(0.17), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.28), lineWidth: 1))
    }

    private var unitToggle: some View {
        HStack(spacing: 4) {
            ForEach(WeatherUnit.allCases) { unit in
                Button {
                    model.changeUnit(unit)
                } label: {
                    Text(unit.label)
                        .font(.caption.weight(.black))
                        .foregroundStyle(model.unit == unit ? Color(hex: 0x222033) : .white.opacity(0.72))
                        .frame(width: 30, height: 30)
                        .background(model.unit == unit ? Color(hex: 0xFFD15C) : .clear, in: Circle())
                }
            }
        }
        .padding(4)
        .background(.white.opacity(selectedTab == .details ? 1 : 0.16), in: Capsule())
        .shadow(color: Color.black.opacity(selectedTab == .details ? 0.08 : 0), radius: 12, x: 0, y: 6)
    }

    private func miniPill(_ title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.black))
                .foregroundStyle(Color(hex: 0x222033))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(color, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func statRow(symbol: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .frame(width: 24)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .black))
        }
    }

    private func metricChip(symbol: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.caption)
            Text(value)
                .font(.caption2.weight(.black))
        }
        .foregroundStyle(Color(hex: 0x6E367C))
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(color, in: Capsule())
    }

    private var loadingView: some View {
        VStack(spacing: 18) {
            FigmaCloudIllustration(mode: .home)
                .frame(height: 210)
            ProgressView("Loading forecast")
                .tint(.white)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 42))
                .foregroundStyle(Color(hex: 0xFFD15C))

            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)

            Button {
                Task {
                    await model.search(city: city)
                }
            } label: {
                Text("Try Again")
                    .font(.headline)
                    .foregroundStyle(Color(hex: 0x5A50D8))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(.white, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func formatTemperature(_ value: Double?, unit: String) -> String {
        guard let value else { return "--" }
        return "\(Int(value.rounded()))\(unit)"
    }

    private func formatTemperatureNumber(_ value: Double?) -> String {
        guard let value else { return "--" }
        return "\(Int(value.rounded()))"
    }

    private func formatTime(_ value: String) -> String {
        String(value.split(separator: "T").last?.prefix(5) ?? "--")
    }

    private func formatWeekday(_ value: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        guard let date = formatter.date(from: value) else {
            return value
        }

        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

private struct FigmaCloudIllustration: View {
    enum Mode {
        case home
        case detail
    }

    let mode: Mode

    var body: some View {
        ZStack {
            if mode == .home {
                CrescentMoon()
                    .fill(Color(hex: 0x5149C8))
                    .frame(width: 54, height: 54)
                    .offset(x: 38, y: -54)

                SunBurst()
                    .fill(Color(hex: 0xFFD22E))
                    .frame(width: 60, height: 60)
                    .offset(x: 128, y: -16)
            } else {
                SunBurst()
                    .fill(Color(hex: 0xFFD22E))
                    .frame(width: 86, height: 86)
                    .offset(x: 64, y: -42)

                rainDrops
                    .offset(x: 58, y: 42)
            }

            cloudBody
                .shadow(color: Color.black.opacity(mode == .home ? 0.18 : 0.1), radius: 18, x: 0, y: 14)
        }
        .frame(maxWidth: .infinity)
    }

    private var cloudBody: some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color(hex: 0xECEFF6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: mode == .home ? 190 : 180, height: mode == .home ? 74 : 70)
                .offset(y: 30)

            Circle()
                .fill(Color.white)
                .frame(width: mode == .home ? 104 : 96, height: mode == .home ? 104 : 96)
                .offset(x: -42, y: 0)

            Circle()
                .fill(Color.white)
                .frame(width: mode == .home ? 132 : 122, height: mode == .home ? 132 : 122)
                .offset(x: 28, y: -20)

            Circle()
                .fill(Color(hex: 0xF7F9FC))
                .frame(width: mode == .home ? 72 : 70, height: mode == .home ? 72 : 70)
                .offset(x: 92, y: 10)
        }
    }

    private var rainDrops: some View {
        ZStack {
            ForEach(0..<6) { index in
                Capsule()
                    .fill(LinearGradient(colors: [Color(hex: 0x23C6E8), Color(hex: 0x2E62F0)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 14, height: 46)
                    .rotationEffect(.degrees(40))
                    .offset(x: CGFloat(index % 3) * 32 - 32, y: CGFloat(index / 3) * 34)
            }
        }
    }
}

private struct TemperatureCurve: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY + 8))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.35, y: rect.midY - 18),
            control1: CGPoint(x: rect.width * 0.12, y: rect.midY + 2),
            control2: CGPoint(x: rect.width * 0.20, y: rect.midY - 28)
        )
        path.addCurve(
            to: CGPoint(x: rect.width * 0.66, y: rect.midY - 4),
            control1: CGPoint(x: rect.width * 0.48, y: rect.midY - 8),
            control2: CGPoint(x: rect.width * 0.54, y: rect.midY + 8)
        )
        path.addCurve(
            to: CGPoint(x: rect.width, y: rect.midY - 12),
            control1: CGPoint(x: rect.width * 0.78, y: rect.midY - 28),
            control2: CGPoint(x: rect.width * 0.88, y: rect.midY - 3)
        )
        return path
    }
}

private struct SunBurst: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: rect)
        return path
    }
}

private struct CrescentMoon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: rect)
        path.addEllipse(in: rect.offsetBy(dx: rect.width * 0.35, dy: -rect.height * 0.08))
        return path
    }
}

private extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
