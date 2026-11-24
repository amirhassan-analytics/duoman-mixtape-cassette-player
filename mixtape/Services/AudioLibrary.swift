//
//  AudioLibrary.swift
//  mixtape
//
//  Imports audio from Files / iCloud with security-scoped access.
//

import Foundation
import AVFoundation
import UniformTypeIdentifiers

enum AudioLibraryError: LocalizedError {
    case unreadable
    case copyFailed(String)

    var errorDescription: String? {
        switch self {
        case .unreadable:
            return "Could not read that file. Try a local MP3, M4A, or WAV."
        case .copyFailed(let message):
            return message
        }
    }
}

enum AudioImportSupport {
    /// Broad set so MP3 / M4A / WAV / AAC / CAF from Files all show up.
    static var contentTypes: [UTType] {
        var types: [UTType] = [
            .audio,
            .mp3,
            .wav,
            .aiff,
            .mpeg4Audio,
            .mpeg4Movie
        ]
        for ext in ["m4a", "aac", "caf", "flac", "ogg"] {
            if let type = UTType(filenameExtension: ext) {
                types.append(type)
            }
        }
        return types
    }
}

enum AudioLibrary {
    static var root: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = docs.appendingPathComponent("MixtapeAudio", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    /// Copy a user-picked audio file into Documents so playback always works.
    static func importFile(from source: URL, preferredName: String? = nil) throws -> String {
        let accessed = source.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                source.stopAccessingSecurityScopedResource()
            }
        }

        let ext = source.pathExtension.isEmpty ? "m4a" : source.pathExtension.lowercased()
        let rawBase = preferredName ?? source.deletingPathExtension().lastPathComponent
        let base = rawBase
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "/", with: "-")
        let name = "\(base)-\(UUID().uuidString.prefix(8)).\(ext)"
        let dest = root.appendingPathComponent(name)

        var coordinationError: NSError?
        var importError: Error?
        var wrote = false

        let coordinator = NSFileCoordinator()
        coordinator.coordinate(
            readingItemAt: source,
            options: [.withoutChanges],
            error: &coordinationError
        ) { readableURL in
            do {
                if FileManager.default.fileExists(atPath: dest.path) {
                    try FileManager.default.removeItem(at: dest)
                }

                // Data copy is more reliable than copyItem for iCloud / Files stubs.
                let data = try Data(contentsOf: readableURL)
                guard !data.isEmpty else {
                    throw AudioLibraryError.unreadable
                }
                try data.write(to: dest, options: .atomic)
                wrote = true
            } catch {
                importError = error
            }
        }

        if let coordinationError {
            throw AudioLibraryError.copyFailed(coordinationError.localizedDescription)
        }
        if let importError {
            throw AudioLibraryError.copyFailed(importError.localizedDescription)
        }
        guard wrote, FileManager.default.fileExists(atPath: dest.path) else {
            throw AudioLibraryError.unreadable
        }

        return dest.path
    }

    static func resolveLocal(_ pathOrName: String) -> URL? {
        if pathOrName.hasPrefix("http://") || pathOrName.hasPrefix("https://") {
            return URL(string: pathOrName)
        }
        if pathOrName.hasPrefix("/") {
            let url = URL(fileURLWithPath: pathOrName)
            if FileManager.default.fileExists(atPath: url.path) { return url }
        }
        let inLibrary = root.appendingPathComponent(pathOrName)
        if FileManager.default.fileExists(atPath: inLibrary.path) { return inLibrary }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let inDocs = docs.appendingPathComponent(pathOrName)
        if FileManager.default.fileExists(atPath: inDocs.path) { return inDocs }
        return nil
    }

    static func duration(of url: URL) -> TimeInterval {
        let asset = AVURLAsset(url: url)
        let seconds = CMTimeGetSeconds(asset.duration)
        if seconds.isFinite && seconds > 0 {
            return seconds
        }
        return 30
    }

    static func clearAll() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audio = docs.appendingPathComponent("MixtapeAudio", isDirectory: true)
        let cache = audio.appendingPathComponent("Cache", isDirectory: true)
        try? FileManager.default.removeItem(at: cache)
        try? FileManager.default.removeItem(at: audio)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }
}
