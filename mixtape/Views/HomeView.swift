//
//  HomeView.swift
//  mixtape
//
//  iPhone Duo → DuoMan dual panes.
//  Standard iPhone → black metallic DUOMAN deck + insert animation.
//

import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {

    @EnvironmentObject private var store: MixtapeStore
    @EnvironmentObject private var playback: PlaybackService
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var showVoiceRecorder = false
    @State private var showMusicSearch = false
    @State private var showPhoneMusic = false
    @State private var showShareSheet = false
    @State private var showImporter = false
    @State private var showCreate = false
    @State private var shareURL: URL?
    @State private var notice: String?
    @State private var alertMessage: String?
    @State private var editSide: TapeSide = .a
    @State private var selectedTapeID: UUID?
    @State private var homeWidth: CGFloat = 390

    private let hPad: CGFloat = 20

    /// Only true Duo / iPad landscape — dual panes; phones use black deck.
    private var useDuoLayout: Bool {
        sizeClass == .regular && homeWidth >= 700
    }

    private var featured: Mixtape? {
        if let id = selectedTapeID,
           let tape = store.createdMixtapes.first(where: { $0.id == id })
            ?? store.mixtapes.first(where: { $0.id == id }) {
            return tape
        }
        return playback.currentMixtape
            ?? store.createdMixtapes.first
            ?? store.mixtapes.first
    }

    var body: some View {
        ZStack {
            ScreenBackground()

            if let featured {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        header

                        if useDuoLayout {
                            duoHome(featured)
                        } else {
                            classicPhoneHome(featured)
                        }
                    }
                    .padding(.horizontal, hPad)
                    .padding(.top, 4)
                    .padding(.bottom, 120)
                    .background {
                        GeometryReader { geo in
                            Color.clear.preference(key: HomeWidthKey.self, value: geo.size.width)
                        }
                    }
                }
                .onPreferenceChange(HomeWidthKey.self) { homeWidth = $0 }
            } else {
                ScrollView {
                    emptyState
                        .padding(.horizontal, hPad)
                        .padding(.top, 40)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showCreate) {
            NavigationStack {
                CreateTapeView()
            }
        }
        .sheet(isPresented: $showVoiceRecorder) {
            VoiceRecorderSheet { message in
                guard var tape = featured else { return }
                var note = message
                note.side = editSide
                guard tape.canFit(note.durationSeconds, on: editSide) else {
                    alertMessage = "\(editSide.label) is full (30 min). Switch to \(editSide.opposite.label)."
                    return
                }
                tape.voiceMessages.append(note)
                tape.visibility = .private
                paintDuo(&tape)
                store.upsert(tape)
                flash("Voice added to \(editSide.label)")
            }
        }
        .sheet(isPresented: $showMusicSearch) {
            MusicSearchView { song in
                guard var tape = featured else {
                    alertMessage = "Create a mixtape first, then add a song."
                    return
                }
                var copy = song
                copy.side = editSide
                guard tape.canFit(copy.playDuration, on: editSide) else {
                    alertMessage = "\(editSide.label) is full (30 min). Switch to \(editSide.opposite.label)."
                    return
                }
                tape.songs.append(copy)
                paintDuo(&tape)
                store.upsert(tape)
                flash("“\(song.title)” → \(editSide.label)")
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.data, .json]
        ) { result in
            switch result {
            case .success(let url):
                do {
                    let tape = try store.importSharedPackage(from: url)
                    flash("Imported “\(tape.title)”")
                } catch {
                    alertMessage = "That file isn't a valid mixtape package."
                }
            case .failure:
                alertMessage = "Could not open that file."
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareURL {
                ActivityShareSheet(items: [shareURL])
            }
        }
        .sheet(isPresented: $showPhoneMusic) {
            PhoneMusicPicker(
                onPicked: { song in
                    guard var tape = featured else {
                        alertMessage = "Create a mixtape first, then add a song."
                        return
                    }
                    var copy = song
                    copy.side = editSide
                    guard tape.canFit(copy.playDuration, on: editSide) else {
                        showPhoneMusic = false
                        alertMessage = "\(editSide.label) is full (30 min). Switch to \(editSide.opposite.label)."
                        return
                    }
                    tape.songs.append(copy)
                    tape.visibility = .private
                    paintDuo(&tape)
                    store.upsert(tape)
                    flash("iPhone song → \(editSide.label)")
                    showPhoneMusic = false
                },
                onCancel: { showPhoneMusic = false },
                onError: { message in
                    showPhoneMusic = false
                    alertMessage = message
                }
            )
            .ignoresSafeArea()
        }
        .alert("Notice", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
        .overlay(alignment: .bottom) {
            if let notice {
                Text(notice)
                    .font(AppTheme.body(13, weight: .bold))
                    .foregroundStyle(Color(hex: "#121214"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppTheme.accent)
                    .clipShape(Capsule())
                    .padding(.bottom, 92)
            }
        }
    }

    // MARK: - Duo (wide)

    private func duoHome(_ featured: Mixtape) -> some View {
        VStack(spacing: 16) {
            DuoManView(
                mixtape: featured,
                side: activeSide(for: featured),
                isPlaying: playback.isPlaying && playback.currentMixtape?.id == featured.id,
                progress: playback.currentMixtape?.id == featured.id ? playback.progress : 0,
                queue: PlaybackService.buildQueue(from: featured, side: activeSide(for: featured)),
                currentItemID: playback.currentMixtape?.id == featured.id
                    ? playback.currentItem?.id
                    : nil,
                onSelectTape: { tape in
                    selectedTapeID = tape.id
                    editSide = .a
                    flash("Loaded “\(tape.title)”")
                },
                onPrev: { transport(featured, .prev) },
                onPlay: { transport(featured, .toggle) },
                onEnsurePlaying: { transport(featured, .ensurePlay) },
                onNext: { transport(featured, .next) },
                onFlipSide: { flipSide(featured) },
                onSelectTrack: { index in
                    playback.play(
                        mixtape: featured,
                        side: activeSide(for: featured),
                        startingAt: index
                    )
                },
                onOpenCreate: { showCreate = true },
                onSong: { showMusicSearch = true },
                onVoice: { showVoiceRecorder = true },
                onAudio: { showPhoneMusic = true },
                onSend: { sendPrivate(featured) }
            )

            MagneticTapeMeter(
                mixtape: featured,
                selectedSide: editSide
            ) { side in
                selectSide(side, on: featured)
            }
        }
    }

    // MARK: - Classic iPhone

    private func classicPhoneHome(_ featured: Mixtape) -> some View {
        VStack(spacing: 16) {
            ProfessionalRadioView(
                title: featured.title,
                subtitle: nowPlayingSubtitle(for: featured),
                sideLabel: activeSide(for: featured).label.uppercased(),
                side: activeSide(for: featured),
                isPlaying: playback.isPlaying && playback.currentMixtape?.id == featured.id,
                progress: playback.currentMixtape?.id == featured.id ? playback.progress : 0,
                labelImage: featured.labelUIImage,
                tapeFill: TapeCapacity.usedFraction(
                    featured.usedSeconds(on: activeSide(for: featured))
                ),
                onPrev: { transport(featured, .prev) },
                onPlay: { transport(featured, .toggle) },
                onNext: { transport(featured, .next) },
                onFlipSide: { flipSide(featured) },
                onEnsurePlaying: { transport(featured, .ensurePlay) }
            )

            MagneticTapeMeter(
                mixtape: featured,
                selectedSide: editSide
            ) { side in
                selectSide(side, on: featured)
            }

            actionRow
            secondaryRow(for: featured)
            songsOnTape(featured)
            recentSection
        }
    }

    // MARK: - Header / actions (classic)

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            Text("DUOMAN")
                .font(AppTheme.title(useDuoLayout ? 22 : 26, weight: .heavy))
                .tracking(useDuoLayout ? 2 : 1.5)
                .foregroundStyle(AppTheme.ink)

            Spacer(minLength: 8)

            AppearanceToggle(compact: true)

            NavigationLink {
                ProfileView()
            } label: {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 34))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(AppTheme.ink, AppTheme.accent)
            }
            .recorderTap(.soft)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            compactAction("waveform", "Song") { showMusicSearch = true }
            compactAction("mic.fill", "Voice") { showVoiceRecorder = true }
            compactAction("music.note.list", "Audio") { showPhoneMusic = true }
            compactAction("paperplane.fill", "Send") {
                if let featured { sendPrivate(featured) }
            }
        }
    }

    private func secondaryRow(for mixtape: Mixtape) -> some View {
        HStack(spacing: 10) {
            NavigationLink {
                CreateTapeView()
            } label: {
                Label("+ New tape", systemImage: "plus")
                    .font(AppTheme.title(15, weight: .heavy))
                    .foregroundStyle(Color(hex: "#121214"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(AppTheme.accentGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: AppTheme.accentDeep.opacity(0.3), radius: 8, y: 3)
            }
            .recorderTap(.hard)

            NavigationLink {
                MixtapeDetailView(mixtapeID: mixtape.id)
            } label: {
                Label("Open", systemImage: "folder")
                    .font(AppTheme.title(15, weight: .heavy))
                    .foregroundStyle(AppTheme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            }
            .recorderTap(.soft)
        }
    }

    private func compactAction(_ icon: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button {
            ClickSoundService.shared.playClick(style: .hard)
            action()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.yellowDeep)
                Text(title)
                    .font(AppTheme.body(12, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func songsOnTape(_ mixtape: Mixtape) -> some View {
        let queue = PlaybackService.buildQueue(from: mixtape, side: editSide)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(editSide.label) playlist")
                    .font(AppTheme.title(16))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Text("\(queue.count) items")
                    .font(AppTheme.body(13, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Text("Order: voice notes first, then songs. Play fills Side A, then flips to Side B.")
                .font(AppTheme.body(12))
                .foregroundStyle(AppTheme.secondaryText)

            if queue.isEmpty {
                Text("Tap Song / Voice / Audio — items go on \(editSide.label) (max 30 min).")
                    .font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                ForEach(Array(queue.enumerated()), id: \.element.id) { index, item in
                    Button {
                        ClickSoundService.shared.playClick(style: .soft)
                        playback.play(mixtape: mixtape, side: editSide, startingAt: index)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: {
                                switch item {
                                case .song: return "music.note"
                                case .voice: return "mic.fill"
                                }
                            }())
                            .foregroundStyle(AppTheme.yellowDeep)
                            .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(AppTheme.title(14))
                                    .foregroundStyle(AppTheme.ink)
                                    .lineLimit(1)
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

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mixtapes")
                .font(AppTheme.title(18, weight: .heavy))
                .foregroundStyle(AppTheme.ink)

            VStack(spacing: 0) {
                ForEach(store.createdMixtapes.prefix(4)) { mixtape in
                    NavigationLink {
                        MixtapeDetailView(mixtapeID: mixtape.id)
                    } label: {
                        MixtapeRowView(
                            mixtape: mixtape,
                            isFavorite: store.isFavorite(mixtape.id)
                        )
                    }
                    .buttonStyle(.plain)
                    .recorderTap(.soft)

                    if mixtape.id != store.createdMixtapes.prefix(4).last?.id {
                        Divider().padding(.leading, 66)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 10, y: 3)
        }
        .padding(.top, 4)
    }

    private var emptyState: some View {
        SoftPanel {
            VStack(spacing: 14) {
                EmptyHint(
                    icon: "radio",
                    title: "No tape loaded",
                    message: "Create a mixtape to load the DUOMAN deck."
                )
                Button {
                    showCreate = true
                } label: {
                    Text("Create mixtape")
                        .font(AppTheme.title(15))
                        .foregroundStyle(Color(hex: "#121214"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.accentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .recorderTap(.hard)
            }
        }
    }

    // MARK: - Logic

    private enum Transport { case prev, toggle, ensurePlay, next }

    private func activeSide(for mixtape: Mixtape) -> TapeSide {
        if playback.currentMixtape?.id == mixtape.id {
            return playback.currentSide
        }
        return editSide
    }

    private func flipSide(_ mixtape: Mixtape) {
        ClickSoundService.shared.playClick(style: .hard)
        editSide = editSide.opposite
        if playback.currentMixtape?.id == mixtape.id {
            playback.flipSide()
        } else {
            playback.play(mixtape: mixtape, side: editSide)
        }
    }

    private func selectSide(_ side: TapeSide, on mixtape: Mixtape) {
        ClickSoundService.shared.playClick(style: .soft)
        editSide = side
        if playback.currentMixtape?.id == mixtape.id {
            playback.play(mixtape: mixtape, side: side)
        }
    }

    private func transport(_ mixtape: Mixtape, _ kind: Transport) {
        let side = activeSide(for: mixtape)
        switch kind {
        case .prev:
            if playback.currentMixtape?.id == mixtape.id { playback.previous() }
            else { playback.play(mixtape: mixtape, side: side) }
        case .toggle:
            if playback.currentMixtape?.id == mixtape.id { playback.toggle() }
            else { playback.play(mixtape: mixtape, side: side) }
        case .ensurePlay:
            if playback.currentMixtape?.id != mixtape.id {
                playback.play(mixtape: mixtape, side: side)
            } else if !playback.isPlaying {
                playback.toggle()
            }
        case .next:
            if playback.currentMixtape?.id == mixtape.id { playback.next() }
            else { playback.play(mixtape: mixtape, side: side) }
        }
    }

    private func nowPlayingSubtitle(for mixtape: Mixtape) -> String {
        if let item = playback.currentItem, playback.currentMixtape?.id == mixtape.id {
            return "\(playback.currentSide.label) · \(item.title)"
        }
        return mixtape.sideSummary
    }

    private func paintDuo(_ tape: inout Mixtape) {
        tape.design.accentColorHex = "#E8C547"
        tape.design.shellTintHex = "#2A2A2E"
    }

    private func sendPrivate(_ mixtape: Mixtape) {
        do {
            shareURL = try MixtapeShareService.exportPackage(for: mixtape)
            showShareSheet = true
            flash("Private package ready")
        } catch {
            alertMessage = "Could not build the share file."
        }
    }

    private func flash(_ text: String) {
        withAnimation { notice = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { notice = nil }
        }
    }
}

private struct HomeWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 390
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
