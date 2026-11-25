import SwiftUI

struct ContentView: View {

    @StateObject private var store = MixtapeStore()
    @StateObject private var playback = PlaybackService()
    @StateObject private var appearance = AppearanceStore.shared

    var body: some View {
        MainTabView()
            .environmentObject(store)
            .environmentObject(playback)
            .environmentObject(appearance)
            .preferredColorScheme(appearance.colorScheme)
    }
}

#Preview {
    ContentView()
}
