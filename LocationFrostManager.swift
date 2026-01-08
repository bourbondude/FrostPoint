import Foundation
import CoreLocation
import SwiftUI
import MapKit
import Combine

// MARK: - Location + Frost Manager
@MainActor
class LocationFrostManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    // Published UI State
    @Published var forecast: FrostForecast?
    @Published var locationName: String = "Locating..."
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    // Private
    private let locationManager = CLLocationManager()
    private nonisolated let weatherManager = WeatherManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - Location Delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            print("⚠️ No location in array")
            return
        }
        print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        locationManager.stopUpdatingLocation()
        
        // Fetch weather and location name
        Task {
            print("🚀 Starting async tasks...")
            await fetchFrostData(for: location)
            await fetchLocationName(from: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let clError = error as NSError
        
        // Ignore error 0 - this is just "location updates stopped" and is normal
        if clError.domain == kCLErrorDomain && clError.code == 0 {
            print("ℹ️ Ignoring CLError 0 (location updates stopped - this is normal)")
            return
        }
        
        print("❌ Location Error: \(error.localizedDescription)")
        self.errorMessage = "Please enable location access in Settings."
        self.isLoading = false
    }
    
    // MARK: - Fetch Frost Data
    func fetchFrostData(for location: CLLocation) async {
        print("🔍 LocationFrostManager: Starting to fetch frost data...")
        do {
            print("📍 Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            let frostData = try await weatherManager.getFrostData(for: location)
            print("✅ LocationFrostManager: Got forecast - \(frostData.riskLevel.rawValue)")
            self.forecast = frostData
            self.isLoading = false
        } catch {
            print("❌ LocationFrostManager Weather Error: \(error.localizedDescription)")
            print("❌ Full error: \(error)")
            self.errorMessage = "Unable to load weather data."
            self.isLoading = false
        }
    }
    
    // MARK: - Reverse Geocoding with iOS 26 MapKit
    private func fetchLocationName(from location: CLLocation) async {
        do {
            guard let request = MKReverseGeocodingRequest(location: location) else {
                self.locationName = "Unknown Location"
                return
            }
            
            let mapItems = try await request.mapItems
            
            if let mapItem = mapItems.first,
               let addressReps = mapItem.addressRepresentations {
                self.locationName = addressReps.cityWithContext ?? "Unknown Location"
            } else {
                self.locationName = "Unknown Location"
            }
        } catch {
            print("Geocoding failed: \(error.localizedDescription)")
            self.locationName = "Unknown Location"
        }
    }
    
    // MARK: - Retry Method
    func retry() {
        isLoading = true
        errorMessage = nil
        forecast = nil
        locationName = "Locating..."
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - Refresh Method (for pull-to-refresh)
    func refresh() async {
        print("🔄 Refreshing forecast data...")
        
        // Get last known location or request new one
        if let lastLocation = locationManager.location {
            await fetchFrostData(for: lastLocation)
            await fetchLocationName(from: lastLocation)
        } else {
            // No cached location, need to request
            locationManager.startUpdatingLocation()
        }
    }
}
