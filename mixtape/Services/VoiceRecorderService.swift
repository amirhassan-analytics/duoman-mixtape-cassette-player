//
//  VoiceRecorderService.swift
//  mixtape
//

import Foundation
import AVFoundation
import Combine

@MainActor
final class VoiceRecorderService: NSObject, ObservableObject {

    @Published private(set) var isRecording = false
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var lastRecordingURL: URL?
    @Published var permissionDenied = false

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var startedAt: Date?

    func requestPermission() async -> Bool {
        await AudioSessionCoordinator.activate(.playAndRecord)
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func start() async {
        let granted = await requestPermission()
        guard granted else {
            permissionDenied = true
            return
        }

        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("voice-\(UUID().uuidString).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.prepareToRecord()
            recorder.record()
            self.recorder = recorder
            lastRecordingURL = url
            isRecording = true
            duration = 0
            startedAt = Date()
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self, let startedAt = self.startedAt else { return }
                    self.duration = Date().timeIntervalSince(startedAt)
                }
            }
        } catch {
            print("Recording failed: \(error)")
        }
    }

    func stop() -> VoiceMessage? {
        recorder?.stop()
        timer?.invalidate()
        timer = nil
        isRecording = false

        guard let url = lastRecordingURL else { return nil }
        let message = VoiceMessage(
            title: "Voice note",
            fileURL: url.path,
            durationSeconds: max(duration, 1)
        )
        return message
    }

    func cancel() {
        recorder?.stop()
        timer?.invalidate()
        timer = nil
        isRecording = false
        if let url = lastRecordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        lastRecordingURL = nil
        duration = 0
    }
}
