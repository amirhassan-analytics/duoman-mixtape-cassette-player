//
//  Mixtape.swift
//  mixtape
//

import Foundation

enum MixtapeVisibility: String, Codable, CaseIterable {
    case `private`
    case `public`
    case inviteOnly

    var displayName: String {
        switch self {
        case .private: return "private"
        case .public: return "public"
        case .inviteOnly: return "invite only"
        }
    }
}

struct Mixtape: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var creatorID: UUID?

    var songs: [Song] = []
    var voiceMessages: [VoiceMessage] = []

    var theme: MixtapeTheme = .luxuryPurple
    var visibility: MixtapeVisibility = .private
    var design: TapeDesign = TapeDesign()

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var songCount: Int {
        songs.count
    }

    // MARK: Magnetic sides

    func songs(on side: TapeSide) -> [Song] {
        songs.filter { $0.side == side }
    }

    func voices(on side: TapeSide) -> [VoiceMessage] {
        voiceMessages.filter { $0.side == side }
    }

    func usedSeconds(on side: TapeSide) -> TimeInterval {
        songs(on: side).reduce(0) { $0 + $1.playDuration }
            + voices(on: side).reduce(0) { $0 + max($1.durationSeconds, 0) }
    }

    func remainingSeconds(on side: TapeSide) -> TimeInterval {
        max(TapeCapacity.sideSeconds - usedSeconds(on: side), 0)
    }

    func canFit(_ seconds: TimeInterval, on side: TapeSide) -> Bool {
        usedSeconds(on: side) + seconds <= TapeCapacity.sideSeconds
    }

    var sideSummary: String {
        "A \(TapeCapacity.format(usedSeconds(on: .a))) · B \(TapeCapacity.format(usedSeconds(on: .b))) / 30:00"
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description, creatorID, songs, voiceMessages
        case theme, visibility, design, createdAt, updatedAt
    }

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        creatorID: UUID? = nil,
        songs: [Song] = [],
        voiceMessages: [VoiceMessage] = [],
        theme: MixtapeTheme = .luxuryPurple,
        visibility: MixtapeVisibility = .private,
        design: TapeDesign = TapeDesign(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.creatorID = creatorID
        self.songs = songs
        self.voiceMessages = voiceMessages
        self.theme = theme
        self.visibility = visibility
        self.design = design
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        creatorID = try container.decodeIfPresent(UUID.self, forKey: .creatorID)
        songs = try container.decodeIfPresent([Song].self, forKey: .songs) ?? []
        voiceMessages = try container.decodeIfPresent([VoiceMessage].self, forKey: .voiceMessages) ?? []
        theme = try container.decodeIfPresent(MixtapeTheme.self, forKey: .theme) ?? .luxuryPurple
        visibility = try container.decodeIfPresent(MixtapeVisibility.self, forKey: .visibility) ?? .private
        design = try container.decodeIfPresent(TapeDesign.self, forKey: .design) ?? TapeDesign()
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
}
