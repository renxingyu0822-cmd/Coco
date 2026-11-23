//
//  WeatherCard.swift
//  Coco
//
//  The weather as a picture, shown under Coco's answer:
//
//  ┌──────────────────────────────────┐
//  │ ☁️  Hanover · Tomorrow, Tue 24 Nov │
//  │     Overcast                     │
//  │  3°        Low -1° · High 3°     │
//  │  💧 0 % rain    💨 8 km/h         │
//  │  Weather data: Open-Meteo.com    │
//  └──────────────────────────────────┘
//
//  The numbers come straight from the weather tool on the server (never from the
//  model's words), sent as a "card" with the reply (server/app/tools/__init__.py).
//  Pictures = Apple's weather symbols (same look as the iPhone Weather app).
//

import SwiftUI

// what the server sends for one weather card (field names = server's JSON)
struct WeatherInfo: Codable, Equatable {
    struct Now: Codable, Equatable {
        let temperature_c: Double
        let feels_like_c: Double
        let weather: String
        let wind_kmh: Double
        let code: Int
        let is_day: Bool
    }
    let city: String
    let country: String
    let day: String              // "tomorrow, Tuesday 24 November"
    let weather: String          // "overcast"
    let code: Int                // weather code -> picture
    let low_c: Double
    let high_c: Double
    let chance_of_rain_percent: Int?
    let max_wind_kmh: Double?
    let now: Now?                // only for today
}

struct WeatherCard: View {
    let info: WeatherInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // picture + where/when + what
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: Self.symbol(code: info.now?.code ?? info.code, isDay: info.now?.is_day ?? true))
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 46))
                    .frame(width: 56)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(info.city) · \(dayLabel)")
                        .font(.headline)
                    Text((info.now?.weather ?? info.weather).capitalizedFirst)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            // big number: right now (today) or the day's high (other days)
            HStack(alignment: .firstTextBaseline, spacing: 14) {
                Text(degrees(info.now?.temperature_c ?? info.high_c))
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                VStack(alignment: .leading, spacing: 2) {
                    if let now = info.now {
                        Text("Feels like \(degrees(now.feels_like_c))")
                    }
                    Text("Low \(degrees(info.low_c)) · High \(degrees(info.high_c))")
                }
                .font(.title3)
                .foregroundStyle(.secondary)
            }

            // rain + wind
            HStack(spacing: 22) {
                if let rain = info.chance_of_rain_percent {
                    Label("\(rain) % rain", systemImage: "drop.fill")
                }
                if let wind = info.now?.wind_kmh ?? info.max_wind_kmh {
                    Label("\(Int(wind.rounded())) km/h", systemImage: "wind")
                }
            }
            .font(.title3)

            // the free plan asks us to credit them
            Text("Weather data: Open-Meteo.com")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemBackground)))
        .accessibilityElement(children: .combine)
    }

    private func degrees(_ c: Double) -> String { "\(Int(c.rounded()))°" }

    // "tomorrow, Tuesday 24 November" -> "Tomorrow, Tue 24 Nov"; "Friday 27 November" -> "Fri 27 Nov"
    private var dayLabel: String {
        info.day.split(separator: " ").map { word in
            let w = String(word)
            let long = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday",
                        "January", "February", "March", "April", "June", "July", "August",
                        "September", "October", "November", "December"]
            return long.contains(w) ? String(w.prefix(3)) : w
        }.joined(separator: " ").capitalizedFirst
    }

    // weather code (WMO, from Open-Meteo) -> Apple weather symbol
    static func symbol(code: Int, isDay: Bool) -> String {
        switch code {
        case 0, 1:       return isDay ? "sun.max.fill" : "moon.stars.fill"
        case 2:          return isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case 3:          return "cloud.fill"
        case 45, 48:     return "cloud.fog.fill"
        case 51...57:    return "cloud.drizzle.fill"
        case 65, 82:     return "cloud.heavyrain.fill"
        case 61...67, 80...82: return "cloud.rain.fill"
        case 71...77, 85, 86:  return "cloud.snow.fill"
        case 95...99:    return "cloud.bolt.rain.fill"
        default:         return "cloud.fill"
        }
    }
}

private extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}

#Preview {
    VStack(spacing: 16) {
        WeatherCard(info: WeatherInfo(city: "Beijing", country: "China", day: "today, Tuesday 24 November",
            weather: "partly cloudy", code: 2, low_c: -1.6, high_c: 5.0, chance_of_rain_percent: 0, max_wind_kmh: 10.2,
            now: .init(temperature_c: -1.5, feels_like_c: -6.3, weather: "clear sky", wind_kmh: 8.4, code: 0, is_day: false)))
        WeatherCard(info: WeatherInfo(city: "Hanover", country: "Germany", day: "tomorrow, Tuesday 24 November",
            weather: "light rain", code: 61, low_c: -1.3, high_c: 2.9, chance_of_rain_percent: 70, max_wind_kmh: 7.9, now: nil))
    }
    .padding()
}
