//
//  CreateTapeView.swift
//  mixtape
//

import SwiftUI

struct CreateTapeView: View {

    @EnvironmentObject private var store: MixtapeStore
    @EnvironmentObject private var playback: PlaybackService
    @Environment(\.dismiss) private var dismiss

    @StateObject private var designer = TapeDesignerViewModel()
    @State private var showAddSong = false
    @State private var showMusicSearch = false
    @State private var showVoiceRecorder = false
    @State private var showPhoneMusic = false
    @State private var savedToast = false
    @State private var alertMessage: String?

    private let card = AppTheme.surface
    private let ink = AppTheme.ink

    var body: some View {
        ZStack {
            ScreenBackground()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 10)

                segmentControl
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        previewCard

                        switch designer.segment {
                        case .design:
                            designSection
                        case .music:
                            musicSection
                        case .options:
                            optionsSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showAddSong) {
            AddSongSheet { song in
                if !designer.addSong(song) {
                    alertMessage = designer.capacityWarning
                }
            }
        }
        .sheet(isPresented: $showMusicSearch) {
            MusicSearchView { song in
                designer.segment = .music
                if !designer.addSong(song) {
                    alertMessage = designer.capacityWarning
                }
            }
        }
        .sheet(isPresented: $showVoiceRecorder) {
            VoiceRecorderSheet { message in
                designer.visibility = .private
                if !designer.addVoice(message) {
                    alertMessage = designer.capacityWarning
                }
            }
        }
        .sheet(isPresented: $showPhoneMusic) {
            PhoneMusicPicker(
                onPicked: { song in
                    designer.visibility = .private
                    designer.segment = .music
                    showPhoneMusic = false
                    if !designer.addSong(song) {
                        alertMessage = designer.capacityWarning
                    }
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
            if savedToast {
                Text("Saved")
                    .font(AppTheme.title(13))
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(AppTheme.yellow)
                    .clipShape(Capsule())
                    .padding(.bottom, 24)
            }
        }
        .onChange(of: designer.title) { _, _ in designer.refreshLabelImage() }
        .onChange(of: designer.selectedColorHex) { _, _ in designer.refreshLabelImage() }
    }

    // MARK: - Top

    private var topBar: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .foregroundStyle(AppTheme.sportsBlue)
            .sportsClick(.soft)

            Spacer()

            Text("Create mixtape")
                .font(AppTheme.title(17))
                .foregroundStyle(ink)

            Spacer()

            Button("Done") {
                save()
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(AppTheme.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(AppTheme.yellow)
            .clipShape(Capsule())
            .sportsClick(.hard)
        }
    }

    private var segmentControl: some View {
        HStack(spacing: 4) {
            ForEach(CreateTapeSegment.allCases) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        designer.segment = item
                    }
                } label: {
                    Text(item.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(designer.segment == item ? ink : ink.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background {
                            if designer.segment == item {
                                Capsule().fill(card)
                                    .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
                            }
                        }
                }
                .sportsClick(.soft)
            }
        }
        .padding(4)
        .background(AppTheme.surfaceLight)
        .clipShape(Capsule())
    }

    private var previewCard: some View {
        VStack(spacing: 10) {
            Text("LIVE PREVIEW")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(ink.opacity(0.4))
                .frame(maxWidth: .infinity, alignment: .leading)

            RealisticCassetteView(
                title: designer.title,
                accent: designer.accent,
                shellTint: designer.shellTint,
                labelImage: designer.labelImage,
                isPlaying: designer.isPreviewPlaying || designer.tool == .draw,
                interactive3D: true
            )
            .frame(height: 168)
            .padding(.horizontal, 18)
            .onTapGesture {
                ClickSoundService.shared.playClick(style: .soft)
                designer.isPreviewPlaying.toggle()
            }
        }
        .padding(14)
        .background(card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Design

    private var designSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Customize label")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(ink)

            toolBar
            canvasCard

            Group {
                switch designer.tool {
                case .draw:
                    brushPanel
                case .color:
                    colorPanel
                case .stickers:
                    stickerPanel
                case .text:
                    textPanel
                }
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    private var toolBar: some View {
        HStack(spacing: 8) {
            ForEach(DesignTool.allCases) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        designer.tool = item
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: item.icon)
                            .font(.system(size: 16, weight: .semibold))
                        Text(item.title)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(designer.tool == item ? AppTheme.ink : ink.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(designer.tool == item ? AppTheme.accent : AppTheme.surfaceLight)
                    )
                }
                .sportsClick(.soft)
            }
        }
    }

    private var canvasCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text(canvasHint)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ink.opacity(0.45))

                Spacer()

                Button {
                    ClickSoundService.shared.playClick(style: .soft)
                    designer.undo()
                } label: {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(ink.opacity(0.35))
                }

                Button {
                    ClickSoundService.shared.playClick(style: .soft)
                    designer.redo()
                } label: {
                    Image(systemName: "arrow.uturn.forward.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(ink.opacity(0.35))
                }

                Button {
                    ClickSoundService.shared.playClick()
                    designer.clearDrawing()
                    designer.stickers = []
                    designer.texts = []
                    designer.refreshLabelImage()
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppTheme.sportsRed.opacity(0.75))
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "#FAF6EF"))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    }

                PencilCanvasView(
                    drawing: designer.drawing,
                    inkColor: designer.selectedUIColor,
                    brushSize: designer.brushSize,
                    isDrawingEnabled: designer.tool == .draw,
                    onDrawingChanged: { designer.drawingDidChange($0) }
                )
                .id(designer.canvasResetID)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                GeometryReader { geo in
                    ForEach(designer.stickers) { sticker in
                        Text(sticker.emoji)
                            .font(.system(size: 32 * sticker.scale))
                            .position(
                                x: sticker.x * geo.size.width,
                                y: sticker.y * geo.size.height
                            )
                    }
                    ForEach(designer.texts) { item in
                        Text(item.text)
                            .font(.system(size: item.fontSize, weight: .heavy))
                            .foregroundStyle(Color(hex: item.colorHex))
                            .position(
                                x: item.x * geo.size.width,
                                y: item.y * geo.size.height
                            )
                    }
                }
                .allowsHitTesting(false)
            }
            .frame(height: 200)
            .padding(12)
        }
        .background(card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var canvasHint: String {
        switch designer.tool {
        case .draw: return "Draw on the label"
        case .stickers: return "Tap a sticker below"
        case .text: return "Add text to the label"
        case .color: return "Pick accent & shell color"
        }
    }

    private var brushPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Brush")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(ink)

            HStack(spacing: 12) {
                Circle()
                    .fill(designer.selectedColor)
                    .frame(width: max(8, designer.brushSize), height: max(8, designer.brushSize))
                Slider(value: $designer.brushSize, in: 3...24)
                    .tint(AppTheme.yellow)
                Text("\(Int(designer.brushSize))")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(ink.opacity(0.45))
                    .frame(width: 22)
            }

            colorSwatches
        }
        .padding(14)
        .background(card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var colorPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Accent color")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(ink)

            colorSwatches

            Text("Shell tint")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(ink)

            HStack(spacing: 10) {
                ForEach(shellChoices, id: \.hex) { item in
                    Button {
                        ClickSoundService.shared.playClick(style: .soft)
                        designer.shellTintHex = item.hex
                    } label: {
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(hex: item.hex))
                                .frame(height: 36)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            designer.shellTintHex == item.hex
                                                ? AppTheme.sportsBlue
                                                : Color.black.opacity(0.08),
                                            lineWidth: 2
                                        )
                                }
                            Text(item.name)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(ink.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(14)
        .background(card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var shellChoices: [(hex: String, name: String)] {
        [
            ("#2A2A2E", "Black"),
            ("#1A1A1E", "Charcoal"),
            ("#3A3A3E", "Steel"),
            ("#121214", "Obsidian")
        ]
    }

    private var stickerPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Stickers")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(ink)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                ForEach(designer.stickerChoices, id: \.self) { emoji in
                    Button {
                        ClickSoundService.shared.playClick(style: .soft)
                        designer.addSticker(emoji)
                    } label: {
                        Text(emoji)
                            .font(.system(size: 28))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AppTheme.surfaceLight)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding(14)
        .background(card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var textPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Label text")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(ink)

            TextField("e.g. Summer Vibes", text: $designer.draftText)
                .padding(12)
                .background(AppTheme.surfaceLight)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                ClickSoundService.shared.playClick(style: .hard)
                designer.addTextOverlay()
            } label: {
                Text("Add text to tape")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(AppTheme.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(designer.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(designer.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
        }
        .padding(14)
        .background(card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var colorSwatches: some View {
        HStack(spacing: 10) {
            ForEach(designer.paletteHex, id: \.self) { hex in
                Button {
                    ClickSoundService.shared.playClick(style: .soft)
                    designer.selectedColorHex = hex
                } label: {
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Circle()
                                .stroke(Color.black.opacity(hex == "#FFFFFF" ? 0.12 : 0), lineWidth: 1)
                        }
                        .overlay {
                            if hex == designer.selectedColorHex {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle((hex == "#FFFFFF" || hex == "#F5C400") ? .black : .white)
                            }
                        }
                }
            }
        }
    }

    // MARK: - Music / Options

    private var musicSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add music")
                .font(AppTheme.title(18))
                .foregroundStyle(ink)

            Text(designer.playlistSummary)
                .font(AppTheme.body(13))
                .foregroundStyle(AppTheme.secondaryText)

            MagneticTapeMeter(
                mixtape: designer.draftMixtapePreview,
                selectedSide: designer.selectedSide
            ) { side in
                ClickSoundService.shared.playClick(style: .soft)
                designer.selectedSide = side
            }

            Text("How it works: songs & voice go on Side \(designer.selectedSide.shortLabel). Each side holds 30 minutes. Playback plays Side A, then flips to Side B. Voice notes play before songs on that side.")
                .font(AppTheme.body(12))
                .foregroundStyle(Color(hex: "#5C4A00"))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.yellowSoft)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            musicRow(icon: "magnifyingglass", title: "Search songs", subtitle: "Adds to \(designer.selectedSide.label)") {
                showMusicSearch = true
            }
            musicRow(icon: "mic.fill", title: "Record your voice", subtitle: "Your sound plays with the songs") {
                showVoiceRecorder = true
                designer.visibility = .private
            }
            musicRow(icon: "music.note.list", title: "From my iPhone", subtitle: "Pick a song already on your phone") {
                showPhoneMusic = true
                designer.visibility = .private
            }

            Button {
                ClickSoundService.shared.playClick()
                showAddSong = true
            } label: {
                Text("Type a song manually")
                    .font(AppTheme.body(13, weight: .semibold))
                    .foregroundStyle(AppTheme.sportsBlue)
            }

            let sideVoices = designer.voicesOnSelectedSide()
            let sideSongs = designer.songsOnSelectedSide()

            if sideVoices.isEmpty && sideSongs.isEmpty {
                Text("Nothing on \(designer.selectedSide.label) yet. Search a song or record a voice — it lands on this side.")
                    .font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.top, 4)
            } else {
                Text("\(designer.selectedSide.label) playlist")
                    .font(AppTheme.title(14))
                    .foregroundStyle(ink)
                    .padding(.top, 4)

                ForEach(sideVoices) { voice in
                    HStack {
                        Image(systemName: "mic.circle.fill")
                            .foregroundStyle(AppTheme.recordingRed)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(voice.title)
                                .font(AppTheme.title(14))
                                .foregroundStyle(ink)
                            Text("Voice · \(TapeCapacity.format(voice.durationSeconds))")
                                .font(AppTheme.body(11))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Spacer()
                        Button {
                            designer.removeVoice(voice.id)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppTheme.secondaryText.opacity(0.5))
                        }
                    }
                    .padding(12)
                    .background(card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                ForEach(sideSongs) { song in
                    HStack {
                        Image(systemName: "music.note")
                            .foregroundStyle(AppTheme.sportsBlue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(song.title)
                                .font(AppTheme.title(14))
                                .foregroundStyle(ink)
                            Text("\(song.artist) · \(TapeCapacity.format(song.playDuration))")
                                .font(AppTheme.body(12))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Spacer()
                        Button {
                            ClickSoundService.shared.playClick()
                            designer.songs.removeAll { $0.id == song.id }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppTheme.secondaryText.opacity(0.5))
                        }
                    }
                    .padding(12)
                    .background(card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

    private func musicRow(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button {
            ClickSoundService.shared.playClick(style: .hard)
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.yellow)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.title(15))
                        .foregroundStyle(ink)
                    Text(subtitle)
                        .font(AppTheme.body(12))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppTheme.secondaryText.opacity(0.5))
            }
            .padding(14)
            .background(card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tape details")
                .font(AppTheme.title(18))
                .foregroundStyle(ink)

            labeledField("Title", text: $designer.title)
            labeledField("Subtitle", text: $designer.subtitle)
            labeledField("Description", text: $designer.descriptionText)

            VStack(alignment: .leading, spacing: 10) {
                Text("Who can hear this?")
                    .font(AppTheme.body(12, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)

                Picker("Visibility", selection: $designer.visibility) {
                    Text("Private").tag(MixtapeVisibility.private)
                    Text("Public").tag(MixtapeVisibility.public)
                    Text("Invite").tag(MixtapeVisibility.inviteOnly)
                }
                .pickerStyle(.segmented)

                Text(privacyHelp)
                    .font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                if designer.visibility == .private || designer.visibility == .inviteOnly {
                    Text("After you save, open the tape and tap “Send private songs” to share your audio file with someone.")
                        .font(AppTheme.body(12, weight: .medium))
                        .foregroundStyle(Color(hex: "#5C4A00"))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.yellowSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(14)
            .background(card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var privacyHelp: String {
        switch designer.visibility {
        case .private:
            return "Only people you send the tape file to can play your songs and voice notes."
        case .public:
            return "Anyone can find this tape in Discover."
        case .inviteOnly:
            return "Not listed publicly — share the private tape file with friends only."
        }
    }

    private func labeledField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTheme.body(12, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)
            TextField(title, text: text)
                .font(AppTheme.body(15, weight: .medium))
                .foregroundStyle(AppTheme.ink)
                .padding(12)
                .background(AppTheme.surfaceLight)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(14)
        .background(card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func save() {
        guard !designer.songs.isEmpty || !designer.voiceMessages.isEmpty else {
            alertMessage = "Add a song or voice note first."
            designer.segment = .music
            return
        }
        let mixtape = designer.buildMixtape(creatorID: store.profile.id)
        store.upsert(mixtape)
        withAnimation { savedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation { savedToast = false }
        }
        dismiss()
    }
}
