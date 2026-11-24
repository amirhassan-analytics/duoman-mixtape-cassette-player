//
//  HomeViewModel.swift
//  mixtape
//
//  Home now uses MixtapeStore + PlaybackService via environment.
//  Kept as a lightweight helper for previews if needed.
//

import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var isPlaying = false

    func togglePlayback() {
        isPlaying.toggle()
    }

    func stopPlayback() {
        isPlaying = false
    }
}
