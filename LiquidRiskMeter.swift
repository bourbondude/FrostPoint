import SwiftUI

// MARK: - Main Frost Risk View
struct FrostRiskView: View {
    let forecast: FrostForecast
    let locationName: String
    @ObservedObject var frostManager: LocationFrostManager
    
    @State private var pulseAnimation = false
    @State private var showSettings = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background: Windshield photo that changes based on risk
                Image(getWindshieldImageName())
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()
                
                // Subtle dark overlay for text readability
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                // Content - CENTERED
                VStack(spacing: 20) {
                    // Top bar
                    HStack(spacing: 0) {
                        // Hamburger menu
                        Button(action: {
                            showSettings.toggle()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.5),
                                                Color.white.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                                
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 50, height: 50)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        
                        Spacer()
                        
                        // Location
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                            Text(locationName)
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.3), Color.clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        
                        Spacer()
                        
                        // Balance spacer
                        Color.clear.frame(width: 50, height: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    // Risk circle
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                        
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.2),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                        
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .topLeading,
                                    startRadius: 0,
                                    endRadius: 100
                                )
                            )
                        
                        Circle()
                            .trim(from: 0, to: forecast.riskPercentage)
                            .stroke(getRiskColor(), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 5) {
                            Text("\(Int(forecast.riskPercentage * 100))%")
                                .font(.system(size: 50, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text(forecast.riskLevel.rawValue.uppercased())
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(getRiskColor())
                        }
                    }
                    .frame(width: 200, height: 200)
                    .shadow(color: .white.opacity(0.2), radius: 0, x: 0, y: -2)
                    .shadow(color: .black.opacity(0.4), radius: 25, x: 0, y: 15)
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
                    
                    // Time
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                        Text(forecast.timeDescription)
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .white.opacity(0.1), radius: 0, x: 0, y: -1)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Spacer()
                    
                    // 2x2 Dashboard with Liquid Glass
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            DataCell(icon: "thermometer.medium", title: "Ambient", value: forecast.ambientTempString)
                            Rectangle().fill(Color.white.opacity(0.15)).frame(width: 1)
                            DataCell(icon: "shield.fill", title: "Surface", value: forecast.shieldTempString)
                        }
                        
                        Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1)
                        
                        HStack(spacing: 0) {
                            DataCell(icon: "drop.fill", title: "Dew Point", value: forecast.dewPointString)
                            Rectangle().fill(Color.white.opacity(0.15)).frame(width: 1)
                            DataCell(icon: "gauge.medium", title: "Risk", value: "\(Int(forecast.riskPercentage * 100))%")
                        }
                    }
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.5),
                                        Color.white.opacity(0.2),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: .white.opacity(0.1), radius: 0, x: 0, y: -1)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    .padding(.horizontal, 24)
                    
                    // Description
                    Text(forecast.conditionDescription)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.4),
                                            Color.white.opacity(0.1),
                                            Color.clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: .white.opacity(0.1), radius: 0, x: 0, y: -1)
                        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
                        .padding(.horizontal, 24)
                    
                    // Attribution
                    Link("Weather data by Open-Meteo.com", destination: URL(string: "https://open-meteo.com")!)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, 20)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showSettings) {
            SettingsView(frostManager: frostManager, isPresented: $showSettings)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            pulseAnimation = true
        }
    }
    
    struct DataCell: View {
        let icon: String
        let title: String
        let value: String
        
        var body: some View {
            VStack(spacing: 10) {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.caption)
                    Text(title)
                        .font(.caption2)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                .foregroundColor(.white.opacity(0.7))
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
        }
    }
    
    func getWindshieldImageName() -> String {
        switch forecast.riskLevel {
        case .extreme: return "windshield_heavy"
        case .high: return "windshield_medium"
        case .moderate: return "windshield_light"
        case .low: return "windshield_clear"
        }
    }
    
    func getRiskColor() -> Color {
        switch forecast.riskLevel {
        case .extreme: return .red
        case .high: return .orange
        case .moderate: return .yellow
        case .low: return .green
        }
    }
}

struct FrostRiskView_Previews: PreviewProvider {
    static var previews: some View {
        FrostRiskView(
            forecast: FrostForecast.placeholder,
            locationName: "Greensboro, NC",
            frostManager: LocationFrostManager()
        )
    }
}
