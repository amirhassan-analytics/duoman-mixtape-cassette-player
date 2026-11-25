//
//  PlaybackService.swift
//  mixtape
//
//  Side-aware playback: plays Side A, auto-flips to Side B.
//

import Foundation
import AVFoundation
import Combine
import MediaPlayer
import CryptoKit

enum PlayableItem: Identifiable, Equatable {
    case song(Song)
    case voice(VoiceMessage)

    var id: UUID {
        switch self {
        case .song(let song): return song.id
        case .voice(let voice): return voice.id
        }
    }

    var title: String {
        switch self {
        case .song(let song): return song.title
        case .voice(let voice): return voice.title
        }
    }

    var subtitle: String {
        switch self {
        case .song(let song): return song.artist
        case .voice: return "Voice message"
        }
    }

    var duration: TimeInterval {
        switch self {
        case .song(let song):
            return song.playDuration
        case .voice(let voice):
            return max(voice.durationSeconds, 1)
        }
    }

    var side: TapeSide {
        switch self {
        case .song(let song): return song.side
        case .voice(let voice): return voice.side
        }
    }

    /// Local file URL (nil for remote / missing).
    var fileURL: URL? {
        switch self {
        case .song(let song):
            guard let path = song.externalURL, !path.isEmpty,
                  !path.lowercased().hasPrefix("http") else { return nil }
            return URL(fileURLWithPath: path)
        case .voice(let voice):
            guard let path = voice.fileURL, !path.isEmpty else { return nil }
            return URL(fileURLWithPath: path)
        }
    }

    /// Remote audio preview (HTTP/HTTPS) if the song points at one.
    var remoteURL: URL? {
        guard case .song(let song) = self,
              let path = song.externalURL,
              path.lowercased().hasPrefix("http"),
              let url = URL(string: path) else { return nil }
        let ext = url.pathExtension.lowercased()
        let isAudio = ["m4a", "mp3", "aac", "wav", "caf", "mp4"].contains(ext)
            || url.host?.contains("audio-ssl.itunes.apple.com") == true
            || url.host?.contains("mzstatic.com") == true && !ext.isEmpty
        return isAudio ? url : nil
    }
}

@MainActor
final class PlaybackService: NSObject, ObservableObject {

    @Published private(set) var currentMixtape: Mixtape?
    @Published private(set) var currentSide: TapeSide = .a
    @Published private(set) var queue: [PlayableItem] = []
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var isPlaying = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 1

    private var audioPlayer: AVAudioPlayer?
    private var engine: AVAudioEngine?
    private var timer: Timer?
    private var startedAt: Date?
    private var downloadTask: Task<Void, Never>?
    private var playToken = UUID()
    private var remoteCommandsConfigured = false

    var currentItem: PlayableItem? {
        guard queue.indices.contains(currentIndex) else { return nil }
        return queue[currentIndex]
    }

    override init() {
        super.init()
        configureRemoteCommands()
    }

    // MARK: - Transport

    func play(mixtape: Mixtape, side: TapeSide = .a, startingAt index: Int = 0) {
        stopInternal(keepMixtape: false)
        currentMixtape = mixtape
        currentSide = side
        queue = Self.buildQueue(from: mixtape, side: side)
        guard !queue.isEmpty else {
            // Nothing on this side — try the other side before giving up.
            let other = side.opposite
            let otherQueue = Self.buildQueue(from: mixtape, side: other)
            guard !otherQueue.isEmpty else { return }
            currentSide = other
            queue = otherQueue
            currentIndex = 0
            startCurrent()
            return
        }
        currentIndex = min(max(index, 0), queue.count - 1)
        startCurrent()
    }

    /// Flip the cassette to the other side and start from the top.
    func flipSide() {
        guard let mixtape = currentMixtape else { return }
        let target = currentSide.opposite
        stopInternal(keepMixtape: true)
        currentSide = target
        queue = Self.buildQueue(from: mixtape, side: target)
        currentIndex = 0
        progress = 0
        elapsed = 0
        isPlaying = false
        guard !queue.isEmpty else { return }
        startCurrent()
    }

    func toggle() {
        if isPlaying {
            pause()
        } else if currentMixtape != nil {
            resume()
        }
    }

    func pause() {
        isPlaying = false
        audioPlayer?.pause()
        engine?.pause()
        timer?.invalidate()
        timer = nil
        if let startedAt {
            elapsed += Date().timeIntervalSince(startedAt)
            self.startedAt = nil
        }
        updateNowPlaying()
    }

    func resume() {
        guard currentItem != nil else { return }
        if let audioPlayer {
            audioPlayer.play()
            isPlaying = true
            startedAt = Date()
            startTimer()
        } else if engine != nil {
            try? engine?.start()
            isPlaying = true
            startedAt = Date()
            startTimer()
        } else {
            startCurrent()
        }
        updateNowPlaying()
    }

    func stop() {
        stopInternal(keepMixtape: true)
        progress = 0
        elapsed = 0
        isPlaying = false
        updateNowPlaying()
    }

    func next() {
        guard !queue.isEmpty else { return }
        let nextIndex = currentIndex + 1
        if nextIndex < queue.count {
            currentIndex = nextIndex
            startCurrent()
        } else if currentSide == .a, let mixtape = currentMixtape,
                  !Self.buildQueue(from: mixtape, side: .b).isEmpty {
            // End of Side A → auto-flip to Side B.
            flipSide()
        } else {
            stop()
        }
    }

    func previous() {
        guard !queue.isEmpty else { return }
        if elapsed > 2 || progress > 0.15 {
            startCurrent()
            return
        }
        currentIndex = max(currentIndex - 1, 0)
        startCurrent()
    }

    // MARK: - Starting items

    private func startCurrent() {
        stopInternal(keepMixtape: true)
        guard let item = currentItem else { return }

        duration = item.duration
        elapsed = 0
        progress = 0

        let token = UUID()
        playToken = token

        Task { [weak self] in
            await AudioSessionCoordinator.activate(.playback)
            await MainActor.run {
                guard let self, self.playToken == token else { return }
                self.beginPlayback(item: item, token: token)
            }
        }
    }

    private func beginPlayback(item: PlayableItem, token: UUID) {
        if let url = item.fileURL, FileManager.default.fileExists(atPath: url.path),
           playFile(url, fallback: item.duration) {
            return
        }

        if let remote = item.remoteURL {
            isPlaying = true
            updateNowPlaying()
            downloadTask = Task { [weak self] in
                let local = await Self.downloadPreview(remote)
                guard let self, !Task.isCancelled, self.playToken == token else { return }
                if let local, self.playFile(local, fallback: item.duration) {
                    return
                }
                self.playSynthetic(for: item.duration)
            }
            return
        }

        playSynthetic(for: item.duration)
    }

    @discardableResult
    private func playFile(_ url: URL, fallback: TimeInterval) -> Bool {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            duration = player.duration > 0 ? player.duration : fallback
            player.play()
            audioPlayer = player
            isPlaying = true
            startedAt = Date()
            startTimer()
            updateNowPlaying()
            return true
        } catch {
            print("Audio file failed: \(error)")
            return false
        }
    }

    private static func downloadPreview(_ remote: URL) async -> URL? {
        let cacheDir = FileManager.default.temporaryDirectory.appendingPathComponent("previews", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)

        let digest = SHA256.hash(data: Data(remote.absoluteString.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined().prefix(24)
        let ext = remote.pathExtension.isEmpty ? "m4a" : remote.pathExtension
        let dest = cacheDir.appendingPathComponent("\(name).\(ext)")

        if FileManager.default.fileExists(atPath: dest.path) { return dest }

        do {
            let (tmp, response) = try await URLSession.shared.download(from: remote)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                return nil
            }
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.moveItem(at: tmp, to: dest)
            return dest
        } catch {
            print("Preview download failed: \(error)")
            return nil
        }
    }

    private func playSynthetic(for length: TimeInterval) {
        let playLength = min(max(length, 4), 18)
        duration = playLength

        let engine = AVAudioEngine()
        let phaseBox = PhaseBox()

        let osc = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let frames = Int(frameCount)
            for buffer in abl {
                guard let data = buffer.mData?.assumingMemoryBound(to: Float.self) else { continue }
                for frame in 0..<frames {
                    let t = phaseBox.value
                    let sample = sin(2 * .pi * 220 * t) * 0.07
                        + sin(2 * .pi * 277.2 * t) * 0.045
                        + sin(2 * .pi * 329.6 * t) * 0.03
                    data[frame] = Float(sample)
                    phaseBox.value += 1.0 / 44100.0
                }
            }
            return noErr
        }

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        engine.attach(osc)
        engine.connect(osc, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.5

        do {
            try engine.start()
            self.engine = engine
        } catch {
            print("Synthetic audio failed: \(error)")
        }
        isPlaying = true
        startedAt = Date()
        startTimer()
        updateNowPlaying()
    }

    private func startTimer() {
        timer?.invalidate()
        let newTimer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }

    private func tick() {
        guard isPlaying else { return }

        if let player = audioPlayer {
            elapsed = player.currentTime
            duration = max(player.duration, 0.1)
            progress = min(elapsed / duration, 1)
            // End of file is handled by the AVAudioPlayerDelegate.
            return
        }

        let live = startedAt.map { Date().timeIntervalSince($0) } ?? 0
        let totalElapsed = elapsed + live
        progress = min(totalElapsed / max(duration, 0.1), 1)

        if totalElapsed >= duration {
            next()
        }
    }

    private func stopInternal(keepMixtape: Bool) {
        downloadTask?.cancel()
        downloadTask = nil
        playToken = UUID()
        timer?.invalidate()
        timer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        engine?.stop()
        engine = nil
        startedAt = nil
        if !keepMixtape {
            currentMixtape = nil
            queue = []
            currentIndex = 0
            currentSide = .a
        }
    }

    // MARK: - Queue

    /// Voice notes linked to a song play before it; unlinked voice notes lead the side.
    static func buildQueue(from mixtape: Mixtape, side: TapeSide) -> [PlayableItem] {
        let sideSongs = mixtape.songs(on: side)
        let sideVoices = mixtape.voices(on: side)
        let songIDs = Set(sideSongs.map(\.id))

        var items: [PlayableItem] = []

        // Orphan voices (no link, or linked to a song that isn't on this side) first.
        for voice in sideVoices where voice.linkedSongID == nil || !songIDs.contains(voice.linkedSongID!) {
            items.append(.voice(voice))
        }

        let linked = Dictionary(grouping: sideVoices.filter {
            guard let id = $0.linkedSongID else { return false }
            return songIDs.contains(id)
        }) { $0.linkedSongID! }

        for song in sideSongs {
            for voice in linked[song.id] ?? [] {
                items.append(.voice(voice))
            }
            items.append(.song(song))
        }
        return items
    }

    // MARK: - Lock screen / remote commands

    private func configureRemoteCommands() {
        guard !remoteCommandsConfigured else { return }
        remoteCommandsConfigured = true
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                guard let self, !self.isPlaying else { return }
                self.toggle()
            }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isPlaying else { return }
                self.toggle()
            }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.toggle() }
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.next() }
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.previous() }
            return .success
        }
    }

    private func updateNowPlaying() {
        guard let item = currentItem, let mixtape = currentMixtape else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        let live = startedAt.map { Date().timeIntervalSince($0) } ?? 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: item.title,
            MPMediaItemPropertyArtist: item.subtitle,
            MPMediaItemPropertyAlbumTitle: "\(mixtape.title) · \(currentSide.label)",
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsed + live,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
    }
}

private final class PhaseBox: @unchecked Sendable {
    var value: Double = 0
}

extension PlaybackService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let id = ObjectIdentifier(player)
        Task { @MainActor in
            guard let current = self.audioPlayer, ObjectIdentifier(current) == id else { return }
            self.next()
        }
    }
}
