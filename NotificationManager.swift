import Foundation
import UserNotifications
import SwiftUI
import Combine

@MainActor
class NotificationManager: ObservableObject {
    
    @Published var isAuthorized = false
    @Published var scheduledTime: Date = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
    
    init() {
        checkAuthorization()
    }
    
    // MARK: - Check Authorization
    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Request Permission
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("❌ Notification permission error: \(error)")
            return false
        }
    }
    
    // MARK: - Schedule Daily Frost Alert
    func scheduleDailyFrostAlert(at time: Date, forecast: FrostForecast) async {
        // First ensure we have permission
        if !isAuthorized {
            let granted = await requestAuthorization()
            if !granted {
                print("❌ Notification permission denied")
                return
            }
        }
        
        // Cancel any existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "🧊 Frost Alert"
        content.body = createNotificationMessage(for: forecast)
        content.sound = .default
        content.badge = 1
        
        // Create trigger for daily at specified time
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "daily-frost-alert",
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Frost notification scheduled for \(formatTime(time))")
        } catch {
            print("❌ Error scheduling notification: \(error)")
        }
    }
    
    // MARK: - Cancel Notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("🚫 All notifications cancelled")
    }
    
    // MARK: - Create Notification Message
    private func createNotificationMessage(for forecast: FrostForecast) -> String {
        switch forecast.riskLevel {
        case .extreme:
            return "⚠️ Extreme frost risk \(forecast.timeDescription.lowercased()). Cover your windshield tonight! Surface temp: \(forecast.shieldTempString)"
        case .high:
            return "❄️ High frost risk \(forecast.timeDescription.lowercased()). Allow extra time to defrost. Surface temp: \(forecast.shieldTempString)"
        case .moderate:
            return "☁️ Moderate frost risk \(forecast.timeDescription.lowercased()). Light frost possible. Surface temp: \(forecast.shieldTempString)"
        case .low:
            return "✅ Low frost risk \(forecast.timeDescription.lowercased()). Clear conditions expected. Surface temp: \(forecast.shieldTempString)"
        }
    }
    
    // MARK: - Format Time
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
