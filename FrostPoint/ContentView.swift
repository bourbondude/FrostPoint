import SwiftUI

struct ContentView: View {
    @StateObject private var manager = LocationFrostManager()
    
    var body: some View {
        ZStack {
            // STATE 1: Loading
            if manager.isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Checking local weather...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            // STATE 2: Error
            else if let errorMessage = manager.errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Unable to load data")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Retry") {
                        manager.retry()
                    }
                    .buttonStyle(.bordered)
                }
            }
            // STATE 3: Success
            else if let forecast = manager.forecast {
                GeometryReader { geometry in
                    ScrollView {
                        FrostRiskView(
                            forecast: forecast,
                            locationName: manager.locationName,
                            frostManager: manager
                        )
                        .frame(minHeight: geometry.size.height)
                    }
                    .refreshable {
                        await manager.refresh()
                    }
                }
                .transition(.opacity.animation(.easeIn))
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .preferredColorScheme(.dark)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
