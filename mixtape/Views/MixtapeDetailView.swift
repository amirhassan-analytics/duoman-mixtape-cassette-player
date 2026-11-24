//
//  MixtapeDetailView.swift
//  mixtape
//

import SwiftUI
import UIKit

struct MixtapeDetailView: View {

    let mixtapeID: UUID

    @EnvironmentObject private var store: MixtapeStore
    @EnvironmentObject private var playback: PlaybackService
    @State private var receivedToast = false
    @State private var shareURL: URL?
    @State private var showShareSheet = false
    @State private var showVoiceRecorder = false
    @State private var shareError: String?
    @State private var notice: String?

    private var mixtape: Mixtape? {
        store.mixtape(id: mixtapeID)
    }

    var body: some View {
        ZStack {
            ScreenBackground()

            if let mixtape {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        SoftPanel(padding: 16) {
                            VStack(spacing: 14) {
                                RealisticCassetteView(
                                    title: mixtape.title,
                                    accent: mixtape.accentColor,
                                    shellTint: mixtape.shellTintColor,
                                    labelImage: mixtape.labelUIImage,
                                    isPlaying: playback.isPlaying && playback.currentMixtape?.id == mixtape.id,
                                    interactive3D: false
                                )
                                .frame(height: 160)

                                Text(mixtape.title)
                                    .font(AppTheme.title(22))
                                    .foregroundStyle(AppTheme.ink)
                                    .multilineTextAlignment(.center)

                                Text(mixtape.description.isEmpty ? "Personal mixtape" : mixtape.description)
                                    .font(AppTheme.body(14))
                                    .foregroundStyle(AppTheme.secondaryText)
                                    .multilineTextAlignment(.center)

                                Text(mixtape.visibility.displayName)
                                    .font(AppTheme.body(11, weight: .bold))
                                    .foregroundStyle(AppTheme.ink)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(AppTheme.yellowSoft)
                                    .clipShape(Capsule())

                                if let item = playback.currentItem, playback.currentMixtape?.id == mixtape.id {
                                    Text(item.title)
                                        .font(AppTheme.body(13, weight: .semibold))
                                        .foregroundStyle(AppTheme.ink)
                                    ProgressView(value: playback.progress)
                                        .tint(AppTheme.yellowDeep)
                                }

                                playControls(for: mixtape)
                            }
                        }

                        Button {
                            ClickSoundService.shared.playClick(style: .soft)
                            showVoiceRecorder = true
                        } label: {
                            Label("Add voice note", systemImage: "mic.fill")
                                .font(AppTheme.title(14))
                                .foregroundStyle(AppTheme.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        Button {
                            prepareShare(for: mixtape)
                        } label: {
                            VStack(spacing: 4) {
                                Label("Send private songs", systemImage: "lock.fill")
                                    .font(AppTheme.title(15))
                                Text("Includes your audio + voice notes")
                                    .font(AppTheme.body(11, weight: .medium))
                            }
                            .foregroundStyle(AppTheme.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.yellowGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .sportsClick(.hard)

                        if store.discoverCatalog.contains(where: { $0.id == mixtape.id }) {
                            Button {
                                store.receive(mixtape)
                                flash("Saved to Library")
                            } label: {
                                Label("Keep this tape", systemImage: "square.and.arrow.down")
                                    .font(AppTheme.title(14))
                                    .foregroundStyle(AppTheme.sportsBlue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(AppTheme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .sportsClick(.mechanica)
                        }

                        tracklist(for: mixtape)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            } else {
                EmptyHint(
                    icon: "opticaldisc",
                    title: "Tape not found",
                    message: "This mixtape may have been removed."
                )
            }
        }
        .navigationTitle(mixtape?.title ?? "Mixtape")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let mixtape {
                    Button {
                        ClickSoundService.shared.playClick(style: .soft)
                        store.toggleFavorite(mixtape.id)
                    } label: {
                        Image(systemName: store.isFavorite(mixtape.id) ? "heart.fill" : "heart")
                            .foregroundStyle(store.isFavorite(mixtape.id) ? AppTheme.recordingRed : AppTheme.ink)
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareURL {
                ActivityShareSheet(items: [shareURL])
            }
        }
        .sheet(isPresented: $showVoiceRecorder) {
            VoiceRecorderSheet { message in
                guard var current = store.mixtape(id: mixtapeID) else { return }
                current.voiceMessages.append(message)
                store.upsert(current)
            }
        }
        .alert("Share", isPresented: Binding(
            get: { shareError != nil },
            set: { if !$0 { shareError = nil } }
        )) {
            Button("OK", role: .cancel) { shareError = nil }
        } message: {
            Text(shareError ?? "")
        }
        .overlay(alignment: .bottom) {
            if let notice {
                Text(notice)
                    .font(AppTheme.body(13, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppTheme.yellow)
                    .clipShape(Capsule())
                    .padding(.bottom, 24)
            }
        }
    }

    private func prepareShare(for mixtape: Mixtape) {
        ClickSoundService.shared.playClick(style: .hard)
        do {
            shareURL = try MixtapeShareService.exportPackage(for: mixtape)
            showShareSheet = true
        } catch {
            shareError = "Could not build the share file."
        }
    }

    private func flash(_ text: String) {
        withAnimation { notice = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { notice = nil }
        }
    }

    private func playControls(for mixtape: Mixtape) -> some View {
        let playing = playback.isPlaying && playback.currentMixtape?.id == mixtape.id
        return HStack(spacing: 28) {
            Button {
                if playback.currentMixtape?.id == mixtape.id {
                    playback.previous()
                } else {
                    playback.play(mixtape: mixtape)
                }
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
            }
            .sportsClick(.mechanica)

            Button {
                if playback.currentMixtape?.id == mixtape.id {
                    playback.toggle()
                } else {
                    playback.play(mixtape: mixtape)
                }
            } label: {
                Image(systemName: playing ? "pause.fill" : "play.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: 64, height: 64)
                    .background(AppTheme.yellowGradient)
                    .clipShape(Circle())
            }
            .sportsClick(.hard)

            Button {
                if playback.currentMixtape?.id == mixtape.id {
                    playback.next()
                } else {
                    playback.play(mixtape: mixtape)
                }
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
            }
            .sportsClick(.mechanica)
        }
    }

    private func tracklist(for mixtape: Mixtape) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Magnetic playlist")
                .font(AppTheme.title(17))
                .foregroundStyle(AppTheme.ink)

            Text(mixtape.sideSummary)
                .font(AppTheme.body(12, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)

            Text("Voice notes play first on a side, then songs. When Side A ends, the deck flips to Side B.")
                .font(AppTheme.body(12))
                .foregroundStyle(AppTheme.secondaryText)

            ForEach(TapeSide.allCases) { side in
                let queue = PlaybackService.buildQueue(from: mixtape, side: side)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(side.label)
                            .font(AppTheme.title(15))
                            .foregroundStyle(AppTheme.ink)
                        Spacer()
                        Text("\(TapeCapacity.format(mixtape.usedSeconds(on: side))) / 30:00")
                            .font(AppTheme.body(11, weight: .bold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    if queue.isEmpty {
                        Text("Empty reel — add songs or voice on Home / Create.")
                            .font(AppTheme.body(12))
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    ForEach(Array(queue.enumerated()), id: \.element.id) { index, item in
                        Button {
                            ClickSoundService.shared.playClick(style: .soft)
                            playback.play(mixtape: mixtape, side: side, startingAt: index)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: itemIcon(item))
                                    .foregroundStyle(AppTheme.yellowDeep)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(AppTheme.title(14))
                                        .foregroundStyle(AppTheme.ink)
                                    Text("\(item.subtitle) · \(TapeCapacity.format(item.duration))")
                                        .font(AppTheme.body(11))
                                        .foregroundStyle(AppTheme.secondaryText)
                                }

                                Spacer()

                                if playback.currentItem?.id == item.id && playback.currentMixtape?.id == mixtape.id {
                                    Image(systemName: "waveform")
                                        .foregroundStyle(AppTheme.yellowDeep)
                                }
                            }
                            .padding(12)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func itemIcon(_ item: PlayableItem) -> String {
        switch item {
        case .song(let song):
            return song.source == .personalRecording ? "waveform" : "music.note"
        case .voice:
            return "mic.fill"
        }
    }
}

struct ActivityShareSheet: UIViewControllerRepresentable {
    var items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
