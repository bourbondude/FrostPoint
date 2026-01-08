import SwiftUI

struct SettingsView: View {
    @StateObject private var notificationManager = NotificationManager()
    @ObservedObject var frostManager: LocationFrostManager
    @Binding var isPresented: Bool  // Changed from @Environment(\.dismiss)
    
    @State private var notificationsEnabled = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Daily Frost Alerts", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) {
                            if notificationsEnabled {
                                Task {
                                    if let forecast = frostManager.forecast {
                                        await notificationManager.scheduleDailyFrostAlert(
                                            at: notificationManager.scheduledTime,
                                            forecast: forecast
                                        )
                                    }
                                }
                            } else {
                                notificationManager.cancelAllNotifications()
                            }
                        }
                    
                    if notificationsEnabled {
                        DatePicker(
                            "Alert Time",
                            selection: $notificationManager.scheduledTime,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: notificationManager.scheduledTime) {
                            Task {
                                if let forecast = frostManager.forecast {
                                    await notificationManager.scheduleDailyFrostAlert(
                                        at: notificationManager.scheduledTime,
                                        forecast: forecast
                                    )
                                }
                            }
                        }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Receive a daily frost risk alert at your chosen time. The notification will show tomorrow morning's frost forecast.")
                }
                
                Section {
                    HStack {
                        Text("Location")
                        Spacer()
                        Text(frostManager.locationName)
                            .foregroundColor(.secondary)
                    }
                    
                    if let forecast = frostManager.forecast {
                        HStack {
                            Text("Current Risk")
                            Spacer()
                            Text(forecast.riskLevel.rawValue.capitalized)
                                .foregroundColor(getRiskColor(forecast.riskLevel))
                                .bold()
                        }
                        
                        HStack {
                            Text("Expected")
                            Spacer()
                            Text(forecast.timeDescription)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Forecast Info")
                }
                
                Section {
                    Link(destination: URL(string: "https://open-meteo.com")!) {
                        HStack {
                            Text("Weather Data Provider")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }
                }
            }
        }
        .onAppear {
            notificationManager.checkAuthorization()
        }
    }
    
    func getRiskColor(_ level: FrostRiskLevel) -> Color {
        switch level {
        case .extreme: return .red
        case .high: return .orange
        case .moderate: return .yellow
        case .low: return .green
        }
    }
}
