//
//  DuoManView.swift
//  mixtape
//
//  Dual-screen Walkman experience for iPhone Duo (wide) + single-phone hinge sim.
//

import SwiftUI

struct DuoManView: View {

    let mixtape: Mixtape
    var side: TapeSide
    var isPlaying: Bool
    var progress: Double
    var queue: [PlayableItem]
    var currentItemID: UUID?

    var onSelectTape: (Mixtape) -> Void
    var onPrev: () -> Void
    var onPlay: () -> Void
    var onEnsurePlaying: () -> Void
    var onNext: () -> Void
    var onFlipSide: () -> Void
    var onSelectTrack: (Int) -> Void
    var onOpenCreate: () -> Void
    var onSong: () -> Void
    var onVoice: () -> Void
    var onAudio: () -> Void
    var onSend: () -> Void

    @EnvironmentObject private var store: MixtapeStore
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var phase: DuoManPhase = .closed
    @State private var deckPhase: VintagePlayerPhase = .empty
    @State private var reelOverride: CassetteReelMotion? = nil
    @State private var isAnimating = false
    @State private var analogLine = "Ready"

    private var tapeFill: Double {
        TapeCapacity.usedFraction(mixtape.usedSeconds(on: side))
    }

    private var activeReelMotion: CassetteReelMotion {
        if let reelOverride { return reelOverride }
        return isPlaying ? .play : .stopped
    }

    /// Side-by-side Duo panes on iPad / Duo-class regular width.
    private var useDualScreens: Bool {
        sizeClass == .regular
    }

    var body: some View {
        VStack(spacing: 14) {
            topBar

            if useDualScreens {
                dualScreens
                    .frame(minHeight: 440)
            } else {
                singlePhoneStack
            }

            hingeControls
        }
        .onAppear {
            if phase == .closed {
                phase = .open
                deckPhase = .empty
            }
        }
    }

    // MARK: - Top

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("DUOMAN")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(AppTheme.ink)
                Text(phase.statusLine)
                    .font(AppTheme.body(11, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            Text(clockString)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppTheme.chromeGradient)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private var clockString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: Date())
    }

    // MARK: - Dual (iPhone Duo / iPad wide)

    private var dualScreens: some View {
        HStack(spacing: 12) {
            leftPane
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Hinge chrome
            Capsule()
                .fill(AppTheme.chromeGradient)
                .frame(width: 10)
                .padding(.vertical, 24)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 0)

            rightPane
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Single phone: stacked Duo panes

    private var singlePhoneStack: some View {
        VStack(spacing: 12) {
            leftPane
                .frame(minHeight: phase.isBayVisible ? 300 : 360)

            rightPane
                .frame(minHeight: 300)
        }
    }

    @ViewBuilder
    private var leftPane: some View {
        if phase.isBayVisible {
            albumsPane
        } else {
            closedDeckPane
        }
    }

    @ViewBuilder
    private var rightPane: some View {
        if phase.isBayVisible || phase == .closing {
            VintagePlayerBayPanel(
                phase: deckPhase,
                title: mixtape.title,
                side: side,
                labelImage: mixtape.labelUIImage,
                reelMotion: activeReelMotion,
                tapeFill: tapeFill,
                progress: progress,
                hint: bayHint
            )
            .overlay(alignment: .bottom) {
                if deckPhase == .inserting || deckPhase == .doorClosing || deckPhase == .doorOpening {
                    analogEngineBanner
                        .padding(12)
                }
            }
        } else {
            tracklistPane
        }
    }

    private var bayHint: String {
        switch deckPhase {
        case .empty:
            return "Close the Duo-Man to insert a cassette."
        case .doorOpening:
            return "Door opening…"
        case .inserting:
            return "Sliding cassette onto spindles…"
        case .doorClosing:
            return "CLICK… latching door"
        case .loaded:
            return "Tape loaded — reels ready"
        case .ejecting, .ejected:
            return "Ejecting cassette…"
        }
    }

    // MARK: - Open left: Albums

    private var albumsPane: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Albums")
                .font(AppTheme.title(20, weight: .heavy))
                .foregroundStyle(AppTheme.ink)

            // DUOMAN SELECTS card
            VStack(alignment: .leading, spacing: 8) {
                Text("DUOMAN SELECTS")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.85))
                Text(mixtape.title)
                    .font(AppTheme.title(22, weight: .heavy))
                    .foregroundStyle(.white)
                Text(mixtape.sideSummary)
                    .font(AppTheme.body(12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#5B3CC4"), Color(hex: "#2A1A6E")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text("Your tapes")
                .font(AppTheme.title(14, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)

            VStack(spacing: 8) {
                ForEach(store.createdMixtapes.prefix(5)) { tape in
                    Button {
                        ClickSoundService.shared.playClick(style: .soft)
                        onSelectTape(tape)
                    } label: {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(AppTheme.yellowGradient)
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Image(systemName: "opticaldisc")
                                        .foregroundStyle(AppTheme.ink)
                                }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(tape.title)
                                    .font(AppTheme.title(14))
                                    .foregroundStyle(AppTheme.ink)
                                    .lineLimit(1)
                                Text(tape.sideSummary)
                                    .font(AppTheme.body(11))
                                    .foregroundStyle(AppTheme.secondaryText)
                            }

                            Spacer()

                            if tape.id == mixtape.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.yellowDeep)
                            }
                        }
                        .padding(10)
                        .background(
                            tape.id == mixtape.id
                                ? AppTheme.yellowSoft
                                : AppTheme.surface
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                ClickSoundService.shared.playClick(style: .hard)
                onOpenCreate()
            } label: {
                Label("New mixtape", systemImage: "plus")
                    .font(AppTheme.title(14, weight: .heavy))
                    .foregroundStyle(Color(hex: "#121214"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.accentGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }

    // MARK: - Closed left: Deck

    private var closedDeckPane: some View {
        VStack(spacing: 0) {
            VintageCassettePlayerView(
                phase: deckPhase == .empty ? .loaded : deckPhase,
                title: mixtape.title,
                side: side,
                labelImage: mixtape.labelUIImage,
                reelMotion: activeReelMotion,
                tapeFill: tapeFill,
                progress: progress,
                showsOverlayLabels: false,
                compactLayout: true
            )
            .frame(height: 240)
            .padding(.horizontal, 8)
            .padding(.top, 28)

            HStack {
                Text("DUOMAN DECK")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.white.opacity(0.7))

                Spacer()

                Button(action: onFlipSide) {
                    Text(side.label.uppercased())
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color(hex: "#E8C547"))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .sportsClick(.soft)

                HStack(spacing: 6) {
                    Circle()
                        .fill(isPlaying ? Color(hex: "#3DDC84") : AppTheme.sportsRed)
                        .frame(width: 8, height: 8)
                    Text(isPlaying ? "ON AIR" : "STANDBY")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)

            // Transport
            HStack(spacing: 28) {
                transportKey("backward.fill", "REW") {
                    flashTransport(.rewind, action: onPrev)
                }
                playKey
                transportKey("forward.fill", "FF") {
                    flashTransport(.fastForward, action: onNext)
                }
            }
            .padding(.top, 16)

            // Voice dedications strip
            if !mixtape.voiceMessages.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Messages on tape")
                        .font(AppTheme.body(11, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.55))
                    ForEach(mixtape.voices(on: side).prefix(2)) { voice in
                        HStack {
                            Image(systemName: "mic.fill")
                                .foregroundStyle(AppTheme.sportsRed)
                            Text(voice.displayTitle)
                                .font(AppTheme.body(12, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.9))
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.top, 12)
            }

            Button {
                openDuo()
            } label: {
                Text("EJECT · OPEN DUO TO SWAP TAPE")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(Color(hex: "#121214"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "#E8C547"))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .sportsClick(.hard)
            .padding(16)

            Spacer(minLength: 0)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "#2A2A2E"), Color(hex: "#121214"), Color(hex: "#0A0A0C")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 14, y: 6)
    }

    private var playKey: some View {
        Button(action: onPlay) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#E8C547"), Color(hex: "#C4A020")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: Color(hex: "#E8C547").opacity(0.35), radius: 10, y: 4)
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color(hex: "#121214"))
                    .offset(x: isPlaying ? 0 : 2)
            }
        }
        .buttonStyle(.plain)
        .sportsClick(.hard)
    }

    private func transportKey(_ icon: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                Text(label)
                    .font(.system(size: 9, weight: .black, design: .rounded))
            }
            .foregroundStyle(Color.white.opacity(0.9))
            .frame(width: 52, height: 52)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .sportsClick(.mechanica)
    }

    private func flashTransport(_ motion: CassetteReelMotion, action: @escaping () -> Void) {
        VintagePlayerAnimator.flashReel(
            motion: motion,
            setMotion: { reelOverride = $0 },
            then: action
        )
    }

    // MARK: - Closed right: Tracklist

    private var tracklistPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tracklist")
                    .font(AppTheme.title(18, weight: .heavy))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Text(side.label)
                    .font(AppTheme.body(12, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            if queue.isEmpty {
                Text("Open Duo and add Song / Voice / Audio.")
                    .font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.vertical, 20)
            } else {
                ForEach(Array(queue.enumerated()), id: \.element.id) { index, item in
                    Button {
                        ClickSoundService.shared.playClick(style: .soft)
                        onSelectTrack(index)
                    } label: {
                        HStack(spacing: 10) {
                            Text(String(format: "%02d", index + 1))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppTheme.secondaryText)
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

                            if currentItemID == item.id {
                                Image(systemName: "waveform")
                                    .foregroundStyle(AppTheme.yellowDeep)
                            }
                        }
                        .padding(10)
                        .background(
                            currentItemID == item.id
                                ? AppTheme.yellowSoft
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider().padding(.vertical, 4)

            Text("Share & Export")
                .font(AppTheme.title(13, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)

            HStack(spacing: 8) {
                shareChip("paperplane.fill", "Send", onSend)
                shareChip("music.note", "Song", onSong)
                shareChip("mic.fill", "Voice", onVoice)
                shareChip("music.note.list", "Audio", onAudio)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }

    private func shareChip(_ icon: String, _ title: String, _ action: @escaping () -> Void) -> some View {
        Button {
            ClickSoundService.shared.playClick(style: .hard)
            action()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(AppTheme.body(10, weight: .bold))
            }
            .foregroundStyle(AppTheme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(AppTheme.yellowSoft)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Analog engine banner

    private var analogEngineBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Analog Sound Engine")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.yellow)
            Text(analogLine)
                .font(AppTheme.body(11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
            AnalogWaveform()
                .frame(height: 22)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Hinge controls

    private var hingeControls: some View {
        HStack(spacing: 10) {
            Button {
                openDuo()
            } label: {
                Label("Open box", systemImage: "rectangle.split.2x1")
                    .font(AppTheme.title(13, weight: .heavy))
                    .foregroundStyle(AppTheme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isAnimating || phase == .open)
            .opacity(phase == .open ? 0.45 : 1)

            Button {
                closeAndPlay()
            } label: {
                Label(phase == .closed ? "Playing" : "Insert & close", systemImage: "opticaldisc.fill")
                    .font(AppTheme.title(13, weight: .heavy))
                    .foregroundStyle(AppTheme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .foregroundStyle(Color(hex: "#121214"))
                    .background(AppTheme.accentGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isAnimating || phase == .closed)
            .opacity(phase == .closed ? 0.45 : 1)
        }
    }

    // MARK: - Animation sequence

    private func openDuo() {
        guard !isAnimating else { return }
        isAnimating = true
        analogLine = "Ejecting cassette…"
        reelOverride = nil

        VintagePlayerAnimator.eject(
            update: { next in
                deckPhase = next
                if next == .ejecting {
                    withAnimation(.spring(response: 0.65, dampingFraction: 0.84)) {
                        phase = .open
                    }
                }
            },
            onComplete: {
                analogLine = "Ready"
                isAnimating = false
            }
        )
    }

    private func closeAndPlay() {
        guard !isAnimating else { return }
        isAnimating = true
        analogLine = "Door opening → insert → latch"

        withAnimation(.easeInOut(duration: 0.35)) {
            phase = .inserting
        }

        VintagePlayerAnimator.insert(
            update: { next in
                deckPhase = next
                switch next {
                case .inserting:
                    analogLine = "Sliding cassette onto spindles…"
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                        phase = .inserting
                    }
                case .doorClosing:
                    analogLine = "Analog static → engage play head"
                    withAnimation(.easeInOut(duration: 0.7)) {
                        phase = .closing
                    }
                case .loaded:
                    analogLine = "CLICK… PLAY"
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.88)) {
                        phase = .closed
                    }
                default:
                    break
                }
            },
            onComplete: {
                onEnsurePlaying()
                isAnimating = false
            }
        )
    }
}

// MARK: - Tiny waveform for analog engine

private struct AnalogWaveform: View {
    @State private var tick = false

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<24, id: \.self) { i in
                Capsule()
                    .fill(AppTheme.yellow.opacity(0.55 + Double(i % 3) * 0.15))
                    .frame(width: 3, height: barHeight(i))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.35).repeatForever(autoreverses: true)) {
                tick = true
            }
        }
    }

    private func barHeight(_ i: Int) -> CGFloat {
        let base: [CGFloat] = [6, 12, 18, 10, 22, 8, 16, 14, 20, 9]
        let h = base[i % base.count]
        return tick ? h : h * 0.45
    }
}

private extension VoiceMessage {
    var displayTitle: String {
        title.isEmpty ? "Voice note" : title
    }
}
