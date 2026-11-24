//
//  MixtapeStore.swift
//  mixtape
//

import Foundation
import Combine

@MainActor
final class MixtapeStore: ObservableObject {

    @Published var mixtapes: [Mixtape] = []
    @Published var favoriteIDs: Set<UUID> = []
    @Published var receivedIDs: Set<UUID> = []
    @Published var profile: UserProfile
    @Published var discoverCatalog: [Mixtape] = []

    private let mixtapesURL: URL
    private let favoritesURL: URL
    private let receivedURL: URL
    private let profileURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        mixtapesURL = docs.appendingPathComponent("mixtapes.json")
        favoritesURL = docs.appendingPathComponent("favorites.json")
        receivedURL = docs.appendingPathComponent("received.json")
        profileURL = docs.appendingPathComponent("profile.json")

        profile = UserProfile(displayName: "Music Lover", username: "mixtape.user")
        load()
        if discoverCatalog.isEmpty {
            discoverCatalog = Self.seedDiscover()
        }
        if mixtapes.isEmpty {
            mixtapes = Self.seedOwned()
            persist()
        } else {
            applyDuoBlackLook()
        }
    }

    private func applyDuoBlackLook() {
        var changed = false
        for index in mixtapes.indices {
            let shell = mixtapes[index].design.shellTintHex.uppercased()
            if shell == "#FFD84A" || shell == "#FFE56A" || shell == "#FFC933" {
                mixtapes[index].design.accentColorHex = "#E8C547"
                mixtapes[index].design.shellTintHex = "#2A2A2E"
                changed = true
            }
        }
        if changed { persist() }
    }

    var createdMixtapes: [Mixtape] {
        mixtapes
            .filter { !receivedIDs.contains($0.id) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var receivedMixtapes: [Mixtape] {
        mixtapes
            .filter { receivedIDs.contains($0.id) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var favoriteMixtapes: [Mixtape] {
        favoriteIDs.compactMap { id in
            mixtapes.first(where: { $0.id == id })
                ?? discoverCatalog.first(where: { $0.id == id })
        }
        .sorted { $0.updatedAt > $1.updatedAt }
    }

    var publicDiscover: [Mixtape] {
        let ownedPublic = mixtapes.filter { $0.visibility == .public }
        let merged = discoverCatalog + ownedPublic
        var seen = Set<UUID>()
        return merged.filter { seen.insert($0.id).inserted }
    }

    func upsert(_ mixtape: Mixtape) {
        var copy = mixtape
        copy.updatedAt = Date()
        if let index = mixtapes.firstIndex(where: { $0.id == copy.id }) {
            mixtapes[index] = copy
        } else {
            mixtapes.insert(copy, at: 0)
        }
        persist()
    }

    func delete(_ id: UUID) {
        mixtapes.removeAll { $0.id == id }
        favoriteIDs.remove(id)
        receivedIDs.remove(id)
        persist()
    }

    func toggleFavorite(_ id: UUID) {
        if favoriteIDs.contains(id) {
            favoriteIDs.remove(id)
        } else {
            favoriteIDs.insert(id)
        }
        persist()
    }

    func isFavorite(_ id: UUID) -> Bool {
        favoriteIDs.contains(id)
    }

    func receive(_ mixtape: Mixtape) {
        var copy = mixtape
        copy.id = UUID()
        copy.createdAt = Date()
        copy.updatedAt = Date()
        mixtapes.insert(copy, at: 0)
        receivedIDs.insert(copy.id)
        persist()
    }

    @discardableResult
    func importSharedPackage(from url: URL) throws -> Mixtape {
        var copy = try MixtapeShareService.importPackage(from: url)
        copy.id = UUID()
        copy.createdAt = Date()
        copy.updatedAt = Date()
        if copy.visibility == .public { copy.visibility = .private }
        mixtapes.insert(copy, at: 0)
        receivedIDs.insert(copy.id)
        persist()
        return copy
    }

    func updateProfile(_ profile: UserProfile) {
        self.profile = profile
        persist()
    }

    func mixtape(id: UUID) -> Mixtape? {
        mixtapes.first { $0.id == id } ?? discoverCatalog.first { $0.id == id }
    }

    private func persist() {
        save(mixtapes, to: mixtapesURL)
        save(Array(favoriteIDs), to: favoritesURL)
        save(Array(receivedIDs), to: receivedURL)
        save(profile, to: profileURL)
    }

    private func load() {
        if let loaded: [Mixtape] = read(from: mixtapesURL) {
            mixtapes = loaded
        }
        if let favs: [UUID] = read(from: favoritesURL) {
            favoriteIDs = Set(favs)
        }
        if let received: [UUID] = read(from: receivedURL) {
            receivedIDs = Set(received)
        }
        if let loadedProfile: UserProfile = read(from: profileURL) {
            profile = loadedProfile
        }
    }

    private func save<T: Encodable>(_ value: T, to url: URL) {
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            print("Save failed: \(error)")
        }
    }

    private func read<T: Decodable>(from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func seedOwned() -> [Mixtape] {
        [
            Mixtape(
                title: "Summer Vibes",
                description: "Warm nights on magnetic tape",
                songs: [
                    Song(title: "Sunset Drive", artist: "Coastline", source: .appleMusic, durationSeconds: 30),
                    Song(title: "Warm Static", artist: "Neon Coast", source: .appleMusic, durationSeconds: 28)
                ],
                theme: .midnightBlack,
                visibility: .private,
                design: TapeDesign(labelTitle: "Summer Vibes", accentColorHex: "#E8C547", shellTintHex: "#2A2A2E")
            ),
            Mixtape(
                title: "Golden Moments",
                description: "Private dedications on Side A",
                songs: [
                    Song(title: "Sunroom", artist: "Ava Vale", source: .appleMusic, durationSeconds: 26)
                ],
                theme: .midnightBlack,
                visibility: .private,
                design: TapeDesign(labelTitle: "Golden Moments", accentColorHex: "#E8C547", shellTintHex: "#1A1A1E")
            ),
            Mixtape(
                title: "Night Ride",
                description: "Private songs for the drive home",
                songs: [
                    Song(title: "Afterglow", artist: "Northbound", source: .appleMusic, durationSeconds: 24)
                ],
                theme: .midnightBlack,
                visibility: .inviteOnly,
                design: TapeDesign(labelTitle: "Night Ride", accentColorHex: "#E8C547", shellTintHex: "#121214")
            )
        ]
    }

    private static func seedDiscover() -> [Mixtape] {
        [
            Mixtape(
                title: "Summer Vibes",
                description: "Sun, waves, and warm days",
                creatorID: UUID(),
                songs: [
                    Song(title: "Sunset Drive", artist: "Coastline", source: .appleMusic, durationSeconds: 30),
                    Song(title: "Palm Shadows", artist: "Ava Vale", source: .appleMusic, durationSeconds: 28)
                ],
                theme: .silverDream,
                visibility: .public,
                design: TapeDesign(labelTitle: "Summer Vibes", accentColorHex: "#E8C547", shellTintHex: "#2A2A2E")
            ),
            Mixtape(
                title: "Beach Club",
                description: "Weekend tape for the ride",
                creatorID: UUID(),
                songs: [
                    Song(title: "Palm Line", artist: "Coastline", source: .appleMusic, durationSeconds: 26)
                ],
                theme: .midnightBlack,
                visibility: .public,
                design: TapeDesign(labelTitle: "Beach Club", accentColorHex: "#E8C547", shellTintHex: "#1A1A1E")
            ),
            Mixtape(
                title: "City Pulse",
                description: "Late trains and neon signs",
                creatorID: UUID(),
                songs: [
                    Song(title: "Metro Line", artist: "Signal", source: .appleMusic, durationSeconds: 24)
                ],
                theme: .midnightBlack,
                visibility: .public,
                design: TapeDesign(labelTitle: "City Pulse", accentColorHex: "#E8C547", shellTintHex: "#121214")
            )
        ]
    }
}
