//
//  ClickSoundService.swift
//  mixtape
//
//  Classic cassette-recorder transport button sound.
//

import Foundation
import AVFoundation
import UIKit
import SwiftUI

// MARK: - Audio session (background actor — never blocks UI)

/// Owns AVAudioSession configuration on a background actor (fixes hang-risk warnings).
actor AudioSessionCoordinator {

    static let shared = AudioSessionCoordinator()

    enum Mode: Equatable, Sendable {
        case playback
        case playbackMix
        case playAndRecord
    }

    private var lastMode: Mode?

    func activate(_ mode: Mode) {
        let session = AVAudioSession.sharedInstance()
        do {
            if lastMode != mode {
                switch mode {
                case .playback:
                    try session.setCategory(
                        .playback,
                        mode: .default,
                        options: [.allowBluetoothA2DP, .allowAirPlay]
                    )
                case .playbackMix:
                    try session.setCategory(
                        .playback,
                        mode: .default,
                        options: [.mixWithOthers]
                    )
                case .playAndRecord:
                    try session.setCategory(
                        .playAndRecord,
                        mode: .default,
                        options: [.defaultToSpeaker, .allowBluetoothHFP]
                    )
                }
                lastMode = mode
            }
            try session.setActive(true, options: [])
        } catch {
            lastMode = nil
        }
    }

    func currentOutputs() -> [AVAudioSessionPortDescription] {
        AVAudioSession.sharedInstance().currentRoute.outputs
    }

    /// Fire-and-forget from UI / init.
    nonisolated static func activateAsync(_ mode: Mode) {
        Task {
            await shared.activate(mode)
        }
    }

    nonisolated static func activate(_ mode: Mode) async {
        await shared.activate(mode)
    }

    nonisolated static func currentOutputs() async -> [AVAudioSessionPortDescription] {
        await shared.currentOutputs()
    }
}

// MARK: - Click sounds

@MainActor
final class ClickSoundService {

    static let shared = ClickSoundService()

    private var softData: Data?
    private var mechData: Data?
    private var hardData: Data?
    private var currentPlayer: AVAudioPlayer?

    private init() {
        AudioSessionCoordinator.activateAsync(.playbackMix)
        softData = RecorderClickSynth.wavData(for: .soft)
        mechData = RecorderClickSynth.wavData(for: .mechanica)
        hardData = RecorderClickSynth.wavData(for: .hard)
    }

    func playClick(style: ClickStyle = .mechanica) {
        let haptic = UIImpactFeedbackGenerator(style: style.haptic)
        haptic.prepare()
        haptic.impactOccurred(intensity: style.intensity)

        if style != .soft {
            let thud = UIImpactFeedbackGenerator(style: .heavy)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.028) {
                thud.impactOccurred(intensity: 0.5)
            }
        }

        let data: Data?
        switch style {
        case .soft: data = softData
        case .mechanica: data = mechData
        case .hard: data = hardData
        }

        guard let data,
              let player = try? AVAudioPlayer(data: data) else { return }

        player.volume = style.volume
        player.prepareToPlay()
        player.play()
        currentPlayer = player
    }

    enum ClickStyle {
        case mechanica
        case soft
        case hard

        var haptic: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .mechanica: return .medium
            case .soft: return .light
            case .hard: return .heavy
            }
        }

        var intensity: CGFloat {
            switch self {
            case .soft: return 0.65
            case .mechanica: return 0.95
            case .hard: return 1.0
            }
        }

        var volume: Float {
            switch self {
            case .soft: return 0.8
            case .mechanica: return 1.0
            case .hard: return 1.0
            }
        }
    }
}

/// Old cassette deck key: plastic press + mechanical latch clunk.
private enum RecorderClickSynth {

    static func wavData(for style: ClickSoundService.ClickStyle) -> Data? {
        let sampleRate = 44100.0
        let duration: Double
        let latchDelay: Double
        let gain: Double

        switch style {
        case .soft:
            duration = 0.10
            latchDelay = 0.016
            gain = 0.85
        case .mechanica:
            duration = 0.125
            latchDelay = 0.02
            gain = 1.0
        case .hard:
            duration = 0.145
            latchDelay = 0.024
            gain = 1.15
        }

        let frameCount = Int(sampleRate * duration)
        var samples = [Int16](repeating: 0, count: frameCount)

        for i in 0..<frameCount {
            let t = Double(i) / sampleRate

            let keyEnv = exp(-t / 0.007)
            let key =
                sin(2 * .pi * 165 * t) * 0.7 * keyEnv
                + sin(2 * .pi * 290 * t) * 0.3 * keyEnv
                + Double.random(in: -1...1) * 0.1 * exp(-t / 0.0035)

            let lt = max(t - latchDelay, 0)
            let latchOn = t >= latchDelay
            let latchEnv = latchOn ? exp(-lt / 0.009) : 0
            let latch =
                sin(2 * .pi * 1100 * lt) * 0.65 * latchEnv
                + sin(2 * .pi * 1600 * lt) * 0.35 * latchEnv
                + sin(2 * .pi * 240 * lt) * 0.55 * latchEnv
                + Double.random(in: -1...1) * 0.16 * (latchOn ? exp(-lt / 0.0025) : 0)

            let bodyEnv = latchOn ? exp(-lt / 0.04) : 0
            let body =
                sin(2 * .pi * 85 * lt) * 0.5 * bodyEnv
                + sin(2 * .pi * 125 * lt) * 0.25 * bodyEnv

            let sample = (key * 0.4 + latch * 0.85 + body * 0.6) * gain
            let clipped = max(-1.0, min(1.0, sample))
            samples[i] = Int16(clipped * Double(Int16.max) * 0.9)
        }

        return makeWAV(samples: samples, sampleRate: Int(sampleRate))
    }

    private static func makeWAV(samples: [Int16], sampleRate: Int) -> Data {
        let dataSize = samples.count * 2
        var data = Data()
        data.reserveCapacity(44 + dataSize)

        func appendASCII(_ string: String) {
            data.append(contentsOf: string.utf8)
        }
        func appendUInt16(_ value: UInt16) {
            var v = value.littleEndian
            withUnsafeBytes(of: &v) { data.append(contentsOf: $0) }
        }
        func appendUInt32(_ value: UInt32) {
            var v = value.littleEndian
            withUnsafeBytes(of: &v) { data.append(contentsOf: $0) }
        }

        appendASCII("RIFF")
        appendUInt32(UInt32(36 + dataSize))
        appendASCII("WAVE")
        appendASCII("fmt ")
        appendUInt32(16)
        appendUInt16(1)
        appendUInt16(1)
        appendUInt32(UInt32(sampleRate))
        appendUInt32(UInt32(sampleRate * 2))
        appendUInt16(2)
        appendUInt16(16)
        appendASCII("data")
        appendUInt32(UInt32(dataSize))

        for sample in samples {
            var s = sample.littleEndian
            withUnsafeBytes(of: &s) { data.append(contentsOf: $0) }
        }
        return data
    }
}

struct SportsClickButtonStyle: ButtonStyle {
    var style: ClickSoundService.ClickStyle = .mechanica

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .offset(y: configuration.isPressed ? 3 : 0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.interpolatingSpring(stiffness: 560, damping: 24), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    ClickSoundService.shared.playClick(style: style)
                }
            }
    }
}

extension View {
    func sportsClick(_ style: ClickSoundService.ClickStyle = .mechanica) -> some View {
        buttonStyle(SportsClickButtonStyle(style: style))
    }

    func recorderTap(_ style: ClickSoundService.ClickStyle = .mechanica) -> some View {
        simultaneousGesture(
            TapGesture().onEnded {
                ClickSoundService.shared.playClick(style: style)
            }
        )
    }
}
