//
//  CreateMixtapeView.swift
//  mixtape
//
//  Legacy entry point — Create tab now uses CreateTapeView.
//

import SwiftUI

struct CreateMixtapeView: View {
    var body: some View {
        CreateTapeView()
    }
}

struct AddSongSheet: View {

    var onAdd: (Song) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var artist = ""
    @State private var album = ""
    @State private var source: SongSource = .appleMusic
    @State private var duration = 12

    var body: some View {
        NavigationStack {
            Form {
                Section("Track") {
                    TextField("Song title", text: $title)
                    TextField("Artist", text: $artist)
                    TextField("Album (optional)", text: $album)
                }
                Section("Source") {
                    Picker("Source", selection: $source) {
                        Text("Apple Music").tag(SongSource.appleMusic)
                        Text("Personal").tag(SongSource.personalRecording)
                    }
                    Stepper("Preview length: \(duration)s", value: $duration, in: 5...30)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: "#F7F1E6"))
            .navigationTitle("Add Song")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let song = Song(
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            artist: artist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? "Unknown Artist"
                                : artist.trimmingCharacters(in: .whitespacesAndNewlines),
                            album: album.isEmpty ? nil : album,
                            source: source,
                            durationSeconds: duration
                        )
                        onAdd(song)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .preferredColorScheme(.light)
    }
}

struct VoiceRecorderSheet: View {

    var onSave: (VoiceMessage) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recorder = VoiceRecorderService()
    @State private var title = "Voice note"

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Text(format(recorder.duration))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1C1917"))
                    .padding(.top, 40)

                Text(recorder.isRecording ? "Recording..." : "Tap to record a message")
                    .foregroundStyle(Color(hex: "#1C1917").opacity(0.5))

                Button {
                    Task {
                        if recorder.isRecording {
                            if var message = recorder.stop() {
                                message.title = title.isEmpty ? "Voice note" : title
                                onSave(message)
                                dismiss()
                            }
                        } else {
                            await recorder.start()
                        }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(AppTheme.recordingRed.opacity(recorder.isRecording ? 0.25 : 0.15))
                            .frame(width: 120, height: 120)
                            .scaleEffect(recorder.isRecording ? 1.08 : 1)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: recorder.isRecording)

                        Circle()
                            .fill(AppTheme.recordingRed)
                            .frame(width: 72, height: 72)
                            .overlay {
                                Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                    }
                }

                TextField("Message title", text: $title)
                    .padding(14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 24)

                if recorder.permissionDenied {
                    Text("Microphone access is required. Enable it in Settings.")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.recordingRed)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Color(hex: "#F7F1E6").ignoresSafeArea())
            .navigationTitle("Record")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        recorder.cancel()
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private func format(_ value: TimeInterval) -> String {
        let total = Int(value)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
