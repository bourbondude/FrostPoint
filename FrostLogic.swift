import Foundation
import CoreLocation

// 1. Simple, Thread-Safe Risk Level
enum FrostRiskLevel: String, Codable, Sendable {
    case low
    case moderate
    case high
    case extreme
}

// 2. The Data Model (Raw Numbers = Thread Safe)
struct FrostForecast: Sendable {
    let riskPercentage: Double // 0.0 to 1.0
    let riskLevel: FrostRiskLevel
    
    // Raw Celsius values
    let shieldTempC: Double
    let ambientTempC: Double
    let dewPointC: Double
    
    // When the frost is expected
    let expectedTime: Date
    let timeDescription: String // "Tonight at 6:00 AM" or "Tomorrow at 6:30 AM"
    
    let conditionDescription: String
    
    // Helper to get formatted strings safely
    var shieldTempString: String {
        Measurement(value: shieldTempC, unit: UnitTemperature.celsius)
            .formatted(.measurement(width: .abbreviated, usage: .weather))
    }
    
    var ambientTempString: String {
        Measurement(value: ambientTempC, unit: UnitTemperature.celsius)
            .formatted(.measurement(width: .abbreviated, usage: .weather))
    }
    
    var dewPointString: String {
        Measurement(value: dewPointC, unit: UnitTemperature.celsius)
            .formatted(.measurement(width: .abbreviated, usage: .weather))
    }
    
    // Placeholder for Previews
    static var placeholder: FrostForecast {
        FrostForecast(
            riskPercentage: 0.45,
            riskLevel: .moderate,
            shieldTempC: -1.0,
            ambientTempC: 2.0,
            dewPointC: -2.0,
            expectedTime: Date(),
            timeDescription: "Tonight at 6:00 AM",
            conditionDescription: "Frost possible around sunrise"
        )
    }
}

// 3. Enhanced Predictive Frost Risk Calculator
struct FrostBrain {
    
    // MARK: - Main Prediction Function
    nonisolated static func predictOvernightFrost(
        hourlyTemps: [Double],      // Celsius
        hourlyDewPoints: [Double],  // Celsius
        hourlyCloudCover: [Double], // 0-100
        hourlyWindSpeed: [Double],  // mph
        hourlyTimes: [Date]
    ) -> FrostForecast {
        
        let now = Date()
        let calendar = Calendar.current
        
        // STEP 1: Define the prediction window
        // If before 6 AM, predict for this morning
        // If after 6 AM, predict for tomorrow morning
        let currentHour = calendar.component(.hour, from: now)
        let isAfterSunrise = currentHour >= 6
        
        // Find the overnight window (tonight 10 PM - tomorrow 10 AM)
        var overnightIndices: [Int] = []
        
        for (index, time) in hourlyTimes.enumerated() {
            let hour = calendar.component(.hour, from: time)
            let isTonight = calendar.isDate(time, inSameDayAs: now)
            let isTomorrow = calendar.isDate(time, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: now)!)
            
            // Include hours from 10 PM tonight through 10 AM tomorrow
            if (isTonight && hour >= 22) || (isTomorrow && hour <= 10) {
                overnightIndices.append(index)
            } else if !isAfterSunrise && isTonight && hour >= 0 && hour <= 10 {
                // If it's currently before sunrise, include this morning's hours
                overnightIndices.append(index)
            }
        }
        
        // STEP 2: Find the highest risk hour in the overnight window
        var maxRisk: Double = 0.0
        var worstHourForecast: (temp: Double, dewPoint: Double, cloud: Double, wind: Double, time: Date)?
        
        for index in overnightIndices {
            guard index < hourlyTemps.count else { continue }
            
            let temp = hourlyTemps[index]
            let dewPoint = hourlyDewPoints[index]
            let cloud = hourlyCloudCover[index] / 100.0
            let wind = hourlyWindSpeed[index]
            let time = hourlyTimes[index]
            
            // Calculate risk for this hour
            let risk = calculateHourlyRisk(
                ambientC: temp,
                dewPointC: dewPoint,
                cloudCover: cloud,
                windSpeedMph: wind,
                time: time
            )
            
            if risk > maxRisk {
                maxRisk = risk
                worstHourForecast = (temp, dewPoint, cloud, wind, time)
            }
        }
        
        // STEP 3: If we found a risky period, calculate detailed forecast
        guard let worst = worstHourForecast else {
            // No data available - return safe default
            return FrostForecast(
                riskPercentage: 0.0,
                riskLevel: .low,
                shieldTempC: 10.0,
                ambientTempC: 10.0,
                dewPointC: 5.0,
                expectedTime: now,
                timeDescription: "No data available",
                conditionDescription: "Unable to predict frost conditions"
            )
        }
        
        // Calculate radiative cooling for the worst hour
        let cooling = calculateRadiativeCooling(
            ambientC: worst.temp,
            dewPointC: worst.dewPoint,
            cloudCover: worst.cloud
        )
        let shieldTemp = worst.temp - cooling
        
        // Determine risk level
        let level: FrostRiskLevel
        if maxRisk >= 0.75 { level = .extreme }
        else if maxRisk >= 0.50 { level = .high }
        else if maxRisk >= 0.25 { level = .moderate }
        else { level = .low }
        
        // Generate time description
        let timeDesc = generateTimeDescription(for: worst.time, currentDate: now)
        
        // Generate condition description
        let description = generatePredictiveDescription(
            level: level,
            shieldTemp: shieldTemp,
            expectedTime: worst.time
        )
        
        return FrostForecast(
            riskPercentage: maxRisk,
            riskLevel: level,
            shieldTempC: shieldTemp,
            ambientTempC: worst.temp,
            dewPointC: worst.dewPoint,
            expectedTime: worst.time,
            timeDescription: timeDesc,
            conditionDescription: description
        )
    }
    
    // MARK: - Calculate Risk for Single Hour
    nonisolated private static func calculateHourlyRisk(
        ambientC: Double,
        dewPointC: Double,
        cloudCover: Double,
        windSpeedMph: Double,
        time: Date
    ) -> Double {
        
        let cooling = calculateRadiativeCooling(
            ambientC: ambientC,
            dewPointC: dewPointC,
            cloudCover: cloudCover
        )
        let shieldTempC = ambientC - cooling
        let dewPointDepression = shieldTempC - dewPointC
        
        var riskScore: Double = 0.0
        
        // A. Temperature Risk (40 points max)
        if shieldTempC <= -2.0 {
            riskScore += 40 // Hard freeze
        } else if shieldTempC <= 0.0 {
            riskScore += 35 // At/below freezing
        } else if shieldTempC <= 1.0 {
            riskScore += 25 // Just above freezing
        } else if shieldTempC <= 2.0 {
            riskScore += 15 // Cool
        } else if shieldTempC <= 3.0 {
            riskScore += 5 // Low risk
        }
        
        // B. Dew Point Depression Risk (30 points max)
        if dewPointDepression <= 0.5 {
            riskScore += 30 // Frost imminent
        } else if dewPointDepression <= 1.0 {
            riskScore += 25
        } else if dewPointDepression <= 2.0 {
            riskScore += 18
        } else if dewPointDepression <= 3.0 {
            riskScore += 10
        } else if dewPointDepression <= 5.0 {
            riskScore += 5
        }
        
        // C. Wind Speed Risk (20 points max)
        if windSpeedMph < 2.0 {
            riskScore += 20 // Calm
        } else if windSpeedMph < 5.0 {
            riskScore += 15 // Light
        } else if windSpeedMph < 8.0 {
            riskScore += 5 // Moderate
        } else if windSpeedMph >= 10.0 {
            riskScore -= 10 // Strong wind prevents frost
        }
        
        // D. Cloud Cover Risk (10 points max)
        if cloudCover < 0.1 {
            riskScore += 10 // Clear skies
        } else if cloudCover < 0.3 {
            riskScore += 5 // Mostly clear
        } else if cloudCover > 0.7 {
            riskScore -= 5 // Overcast
        }
        
        // E. Time-of-Day Bonus
        let hour = Calendar.current.component(.hour, from: time)
        if hour >= 4 && hour <= 7 {
            riskScore += 10 // Peak frost formation time
        } else if hour >= 2 && hour <= 3 || hour >= 8 && hour <= 9 {
            riskScore += 5
        }
        
        return min(max(riskScore, 0), 100) / 100.0
    }
    
    // MARK: - Radiative Cooling Calculation
    nonisolated private static func calculateRadiativeCooling(
        ambientC: Double,
        dewPointC: Double,
        cloudCover: Double
    ) -> Double {
        var maxCooling: Double = 7.0
        
        let dewPointDepression = ambientC - dewPointC
        if dewPointDepression < 2.0 {
            maxCooling *= 0.7
        } else if dewPointDepression < 5.0 {
            maxCooling *= 0.85
        }
        
        let cloudFactor = 1.0 - (cloudCover * 0.85)
        return maxCooling * cloudFactor
    }
    
    // MARK: - Time Description Generator
    nonisolated private static func generateTimeDescription(for date: Date, currentDate: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let timeString = formatter.string(from: date)
        let hour = calendar.component(.hour, from: date)
        
        // Simple logic: Before midnight = today, after midnight = tomorrow
        if hour >= 0 && hour < 12 {
            // Midnight to noon
            return "Tomorrow at \(timeString)"
        } else {
            // Noon to midnight
            return "Today at \(timeString)"
        }
    }
    
    // MARK: - Predictive Description Generator
    nonisolated private static func generatePredictiveDescription(
        level: FrostRiskLevel,
        shieldTemp: Double,
        expectedTime: Date
    ) -> String {
        let hour = Calendar.current.component(.hour, from: expectedTime)
        let timeContext = (hour >= 4 && hour <= 7) ? "around sunrise" : "overnight"
        
        switch level {
        case .extreme:
            if shieldTemp <= -2.0 {
                return "Hard freeze expected \(timeContext). Cover windshield tonight."
            } else {
                return "Heavy frost highly likely \(timeContext). Prepare now."
            }
        case .high:
            return "Frost probable \(timeContext). Allow extra time to defrost."
        case .moderate:
            return "Light frost possible \(timeContext). Monitor conditions."
        case .low:
            return "Minimal frost risk. Conditions favorable."
        }
    }
}

// 4. The Network Actor (Open-Meteo)
actor WeatherManager {
    private let baseURL = "https://api.open-meteo.com/v1/forecast"
    
    // Internal JSON Models
    private struct OpenMeteoResponse: Decodable {
        let hourly: HourlyWeather
    }
    private struct HourlyWeather: Decodable {
        let time: [String]
        let temperature_2m: [Double]
        let dew_point_2m: [Double]
        let cloud_cover: [Double]
        let wind_speed_10m: [Double]
    }
    
    func getFrostData(for location: CLLocation) async throws -> FrostForecast {
        print("🌍 Fetching frost data for location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        let hourlyData = try await fetchRawData(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
        
        print("📊 Received \(hourlyData.time.count) hourly data points")
        print("🌡️ First temp: \(hourlyData.temperature_2m.first ?? -999)")
        print("💧 First dew point: \(hourlyData.dew_point_2m.first ?? -999)")
        
        // Parse time strings to Date objects
        let formatter = ISO8601DateFormatter()
        let times = hourlyData.time.compactMap { formatter.date(from: $0) }
        
        print("⏰ Parsed \(times.count) valid timestamps")
        
        // Convert wind speed from km/h to mph
        let windsMph = hourlyData.wind_speed_10m.map { $0 * 0.621371 }
        
        let forecast = FrostBrain.predictOvernightFrost(
            hourlyTemps: hourlyData.temperature_2m,
            hourlyDewPoints: hourlyData.dew_point_2m,
            hourlyCloudCover: hourlyData.cloud_cover,
            hourlyWindSpeed: windsMph,
            hourlyTimes: times
        )
        
        print("✅ Generated forecast - Risk: \(Int(forecast.riskPercentage * 100))%, Level: \(forecast.riskLevel.rawValue)")
        
        return forecast
    }
    
    private func fetchRawData(lat: Double, lon: Double) async throws -> HourlyWeather {
        // Request 2 days of hourly data to ensure we cover tonight + tomorrow morning
        let urlString = "\(baseURL)?latitude=\(lat)&longitude=\(lon)&hourly=temperature_2m,dew_point_2m,cloud_cover,wind_speed_10m&forecast_days=2"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        return decoded.hourly
    }
}
