//
//  VoiceMessage.swift
//  mixtape
//

import Foundation

struct VoiceMessage: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var fileURL: String?
    var durationSeconds: Double
    var createdAt: Date = Date()
    /// If set, this voice plays just before that song.
    var linkedSongID: UUID?
    var side: TapeSide = .a

    enum CodingKeys: String, CodingKey {
        case id, title, fileURL, durationSeconds, createdAt, linkedSongID, side
    }

    init(
        id: UUID = UUID(),
        title: String,
        fileURL: String? = nil,
        durationSeconds: Double,
        createdAt: Date = Date(),
        linkedSongID: UUID? = nil,
        side: TapeSide = .a
    ) {
        self.id = id
        self.title = title
        self.fileURL = fileURL
        self.durationSeconds = durationSeconds
        self.createdAt = createdAt
        self.linkedSongID = linkedSongID
        self.side = side
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        fileURL = try container.decodeIfPresent(String.self, forKey: .fileURL)
        durationSeconds = try container.decode(Double.self, forKey: .durationSeconds)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        linkedSongID = try container.decodeIfPresent(UUID.self, forKey: .linkedSongID)
        side = try container.decodeIfPresent(TapeSide.self, forKey: .side) ?? .a
    }
}
