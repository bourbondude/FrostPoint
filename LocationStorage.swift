import Foundation
import CoreLocation

// MARK: - Location Model
struct SavedLocation: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
    
    init(id: UUID = UUID(), name: String, coordinate: CLLocationCoordinate2D, timestamp: Date = Date()) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.timestamp = timestamp
    }
    
    // Manual Codable implementation since CLLocationCoordinate2D isn't Codable
    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude, timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(timestamp, forKey: .timestamp)
    }
}

// MARK: - Location Storage Manager
@MainActor
class LocationStorageManager: ObservableObject {
    @Published var recentLocations: [SavedLocation] = []
    
    private let maxRecent = 3
    private let storageKey = "recentLocations"
    
    init() {
        loadRecentLocations()
    }
    
    func addLocation(_ location: SavedLocation) {
        // Remove if already exists
        recentLocations.removeAll { $0.name == location.name }
        
        // Add to beginning
        recentLocations.insert(location, at: 0)
        
        // Keep only last 3
        if recentLocations.count > maxRecent {
            recentLocations = Array(recentLocations.prefix(maxRecent))
        }
        
        saveRecentLocations()
    }
    
    private func saveRecentLocations() {
        if let encoded = try? JSONEncoder().encode(recentLocations) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadRecentLocations() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([SavedLocation].self, from: data) {
            recentLocations = decoded
        }
    }
    
    func clearHistory() {
        recentLocations.removeAll()
        UserDefaults.standard.
