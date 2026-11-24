//
//  MixtapeShareService.swift
//  mixtape
//

import Foundation

struct SharedTapePackage: Codable {
    var formatVersion: Int = 1
    var exportedAt: Date = Date()
    var mixtape: Mixtape
    var audioPayloads: [String: Data]
}

enum MixtapeShareService {
    static func exportPackage(for mixtape: Mixtape) throws -> URL {
        var audioPayloads: [String: Data] = [:]
        var packaged = mixtape

        for index in packaged.songs.indices {
            if let path = packaged.songs[index].externalURL,
               let local = AudioLibrary.resolveLocal(path),
               local.isFileURL,
               let data = try? Data(contentsOf: local) {
                let name = "song-\(packaged.songs[index].id.uuidString).m4a"
                audioPayloads[name] = data
                packaged.songs[index].externalURL = name
            }
        }

        for index in packaged.voiceMessages.indices {
            if let path = packaged.voiceMessages[index].fileURL,
               let local = AudioLibrary.resolveLocal(path),
               let data = try? Data(contentsOf: local) {
                let name = "voice-\(packaged.voiceMessages[index].id.uuidString).m4a"
                audioPayloads[name] = data
                packaged.voiceMessages[index].fileURL = name
            }
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(SharedTapePackage(mixtape: packaged, audioPayloads: audioPayloads))

        let safe = mixtape.title.replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(safe.isEmpty ? "Mixtape" : safe).mixtape")
        try data.write(to: url, options: .atomic)
        return url
    }

    static func importPackage(from fileURL: URL) throws -> Mixtape {
        let accessed = fileURL.startAccessingSecurityScopedResource()
        defer { if accessed { fileURL.stopAccessingSecurityScopedResource() } }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let package = try decoder.decode(SharedTapePackage.self, from: Data(contentsOf: fileURL))
        var mixtape = package.mixtape

        for (name, bytes) in package.audioPayloads {
            let dest = AudioLibrary.root.appendingPathComponent(name)
            try bytes.write(to: dest, options: .atomic)
            for i in mixtape.songs.indices where mixtape.songs[i].externalURL == name {
                mixtape.songs[i].externalURL = dest.path
                mixtape.songs[i].source = .personalRecording
            }
            for i in mixtape.voiceMessages.indices where mixtape.voiceMessages[i].fileURL == name {
                mixtape.voiceMessages[i].fileURL = dest.path
            }
        }
        return mixtape
    }
}
