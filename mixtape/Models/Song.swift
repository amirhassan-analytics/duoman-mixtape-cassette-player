//
//  Song.swift
//  mixtape
//
//  Created by ManoveKumar on 06/11/2026.
//


import Foundation

enum SongSource: String, Codable, CaseIterable {
    case spotify
    case youtube
    case appleMusic
    case personalRecording

    var displayName: String {
        switch self {
        case .spotify: return "Spotify"
        case .youtube: return "YouTube"
        case .appleMusic: return "Apple Music"
        case .personalRecording: return "Personal"
        }
    }
}

struct Song: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var artist: String
    var album: String?
    var artworkURL: String?
    var externalID: String?
    var externalURL: String?
    var source: SongSource
    var durationSeconds: Int?
    var addedAt: Date = Date()
    var side: TapeSide = .a

    /// Seconds this song occupies on the tape (30 s preview fallback).
    var playDuration: TimeInterval {
        if let durationSeconds, durationSeconds > 0 {
            return TimeInterval(durationSeconds)
        }
        return 30
    }

    enum CodingKeys: String, CodingKey {
        case id, title, artist, album, artworkURL, externalID, externalURL
        case source, durationSeconds, addedAt, side
    }

    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        album: String? = nil,
        artworkURL: String? = nil,
        externalID: String? = nil,
        externalURL: String? = nil,
        source: SongSource,
        durationSeconds: Int? = nil,
        addedAt: Date = Date(),
        side: TapeSide = .a
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.artworkURL = artworkURL
        self.externalID = externalID
        self.externalURL = externalURL
        self.source = source
        self.durationSeconds = durationSeconds
        self.addedAt = addedAt
        self.side = side
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try c.decode(String.self, forKey: .title)
        artist = try c.decode(String.self, forKey: .artist)
        album = try c.decodeIfPresent(String.self, forKey: .album)
        artworkURL = try c.decodeIfPresent(String.self, forKey: .artworkURL)
        externalID = try c.decodeIfPresent(String.self, forKey: .externalID)
        externalURL = try c.decodeIfPresent(String.self, forKey: .externalURL)
        source = try c.decode(SongSource.self, forKey: .source)
        durationSeconds = try c.decodeIfPresent(Int.self, forKey: .durationSeconds)
        addedAt = try c.decodeIfPresent(Date.self, forKey: .addedAt) ?? Date()
        side = try c.decodeIfPresent(TapeSide.self, forKey: .side) ?? .a
    }
}
    