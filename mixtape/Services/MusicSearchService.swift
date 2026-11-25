//
//  MusicSearchService.swift
//  mixtape
//
//  Simple free song search via iTunes Search API (no API key).
//

import Foundation
import Combine

struct MusicSearchResult: Identifiable, Hashable {
    let id: String
    let title: String
    let artist: String
    let artworkURL: String?
    let externalURL: String?
    let source: SongSource
    let durationSeconds: Int?

    func asSong() -> Song {
        Song(
            title: title,
            artist: artist,
            artworkURL: artworkURL,
            externalID: id,
            externalURL: externalURL,
            source: source,
            durationSeconds: durationSeconds ?? 12
        )
    }
}

@MainActor
final class MusicSearchService: ObservableObject {

    @Published var results: [MusicSearchResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func search(_ query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            results = []
            errorMessage = nil
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            var components = URLComponents(string: "https://itunes.apple.com/search")!
            components.queryItems = [
                URLQueryItem(name: "term", value: trimmed),
                URLQueryItem(name: "media", value: "music"),
                URLQueryItem(name: "entity", value: "song"),
                URLQueryItem(name: "limit", value: "25")
            ]
            guard let url = components.url else { return }

            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(iTunesResponse.self, from: data)
            results = decoded.results.compactMap { item in
                guard let track = item.trackName, let artist = item.artistName else { return nil }
                return MusicSearchResult(
                    id: "itunes-\(item.trackId ?? Int.random(in: 1000...999999))",
                    title: track,
                    artist: artist,
                    artworkURL: item.artworkUrl100?.replacingOccurrences(of: "100x100", with: "300x300"),
                    externalURL: item.previewUrl ?? item.trackViewUrl,
                    source: .appleMusic,
                    durationSeconds: item.trackTimeMillis.map { max($0 / 1000, 1) }
                )
            }
            if results.isEmpty {
                errorMessage = "No songs found. Try another search."
            }
        } catch {
            results = []
            errorMessage = "Search failed. Check your connection."
        }
    }
}

private struct iTunesResponse: Decodable {
    let results: [iTunesTrack]
}

private struct iTunesTrack: Decodable {
    let trackId: Int?
    let trackName: String?
    let artistName: String?
    let artworkUrl100: String?
    let trackViewUrl: String?
    let previewUrl: String?
    let trackTimeMillis: Int?
}
