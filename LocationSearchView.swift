import SwiftUI
import MapKit

struct LocationSearchView: View {
    @Environment(\.dismiss) var dismiss
    @State private var locationStorage = LocationStorageManager()
    @ObservedObject var frostManager: LocationFrostManager
    
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search for a city or address", text: $searchText)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            performSearch()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // Content
                List {
                    // Current location
                    Section {
                        Button(action: {
                            // Use current GPS location
                            frostManager.retry()
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.blue)
                                Text("Use Current Location")
                                Spacer()
                            }
                        }
                    }
                    
                    // Recent locations
                    if !locationStorage.recentLocations.isEmpty {
                        Section(header: Text("Recent Locations")) {
                            ForEach(locationStorage.recentLocations) { location in
                                Button(action: {
                                    selectLocation(location)
                                }) {
                                    HStack {
                                        Image(systemName: "clock")
                                            .foregroundColor(.gray)
                                        Text(location.name)
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                    
                    // Search results
                    if !searchResults.isEmpty {
                        Section(header: Text("Search Results")) {
                            ForEach(searchResults, id: \.self) { item in
                                Button(action: {
                                    selectMapItem(item)
                                }) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.name ?? "Unknown")
                                            .font(.body)
                                        if let address = item.placemark.thoroughfare {
                                            Text(address)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        Task {
            do {
                let search = MKLocalSearch(request: request)
                let response = try await search.start()
                searchResults = response.mapItems
                isSearching = false
            } catch {
                print("Search error: \(error)")
                isSearching = false
            }
        }
    }
    
    private func selectMapItem(_ item: MKMapItem) {
        let location = CLLocation(
            latitude: item.placemark.coordinate.latitude,
            longitude: item.placemark.coordinate.longitude
        )
        
        let savedLocation = SavedLocation(
            name: item.name ?? "Unknown Location",
            coordinate: item.placemark.coordinate
        )
        
        locationStorage.addLocation(savedLocation)
        
        // Trigger frost manager to fetch data for this location
        Task {
            await frostManager.fetchFrostData(for: location)
            await frostManager.fetchLocationName(from: location)
        }
        
        dismiss()
    }
    
    private func selectLocation(_ savedLocation: SavedLocation) {
        let location = CLLocation(
            latitude: savedLocation.coordinate.latitude,
            longitude: savedLocation.coordinate.longitude
        )
        
        // Move to top of recent
        locationStorage.addLocation(savedLocation)
        
        // Trigger frost manager to fetch data for this location
        Task {
            await frostManager.fetchFrostData(for: location)
            await frostManager.fetchLocationName(from: location)
        }
        
        dismiss()
    }
}

