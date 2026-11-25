//
//  ProfessionalRadioView.swift
//  mixtape
//
//  Standard iPhone — black metallic DUOMAN deck with real door/insert animation.
//

import SwiftUI

struct ProfessionalRadioView: View {

    var title: String
    var subtitle: String
    var sideLabel: String = "SIDE A"
    var side: TapeSide = .a
    var isPlaying: Bool
    var progress: Double
    var labelImage: UIImage?
    var tapeFill: Double = 0.35

    var onPrev: () -> Void
    var onPlay: () -> Void
    var onNext: () -> Void
    var onFlipSide: (() -> Void)?
    var onEnsurePlaying: (() -> Void)?

    @State private var deckPhase: VintagePlayerPhase = .empty
    @State private var reelOverride: CassetteReelMotion? = nil
    @State private var isAnimating = false
    @State private var didAutoLoad = false
    @State private var cardWidth: CGFloat = 360

    private var reelMotion: CassetteReelMotion {
        if let reelOverride { return reelOverride }
        return isPlaying && deckPhase == .loaded ? .play : .stopped
    }

    /// Extra height so the open door + dropping cassette are visible.
    private var playerHeight: CGFloat {
        min(max(cardWidth * 0.72, 220), 280)
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(deckPhase.statusLabel)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(Color(hex: "#E8C547"))
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 4)

            VintageCassettePlayerView(
                phase: deckPhase,
                title: title,
                side: side,
                labelImage: labelImage,
                reelMotion: reelMotion,
                tapeFill: tapeFill,
                progress: progress,
                brand: "MIXTAPE",
                showsOverlayLabels: false,
                compactLayout: true
            )
            .frame(height: playerHeight)
            .padding(.leading, 6)
            .padding(.trailing, 18)

            HStack(spacing: 8) {
                Text("MIX TAPE")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(Color.white.opacity(0.65))
                    .lineLimit(1)

                Spacer(minLength: 4)

                Button {
                    onFlipSide?()
                } label: {
                    Text(sideLabel)
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: "#121214"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color(hex: "#E8C547"))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .layoutPriority(2)

                HStack(spacing: 5) {
                    Circle()
                        .fill(isPlaying ? Color(hex: "#3DDC84") : AppTheme.sportsRed)
                        .frame(width: 7, height: 7)
                    Text(isPlaying ? "ON AIR" : "STANDBY")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.7))
                        .lineLimit(1)
                }
                .layoutPriority(1)
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)

            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)

                Text(subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            progressBar
                .padding(.horizontal, 18)
                .padding(.top, 12)

            HStack {
                transportButton("backward.fill", "REW") {
                    flashReel(.rewind) { onPrev() }
                }
                Spacer(minLength: 12)
                playButton
                Spacer(minLength: 12)
                transportButton("forward.fill", "FF") {
                    flashReel(.fastForward) { onNext() }
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 14)

            HStack(spacing: 10) {
                Button {
                    replayInsert()
                } label: {
                    Text(deckPhase == .loaded ? "RELOAD" : "INSERT")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isAnimating)

                Button {
                    ejectTape()
                } label: {
                    Text("EJECT")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(Color(hex: "#121214"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#E8C547"))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isAnimating || deckPhase == .empty)
                .opacity(deckPhase == .empty ? 0.45 : 1)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .background {
            GeometryReader { geo in
                Color.clear.preference(key: PhoneDeckWidthKey.self, value: geo.size.width)
            }
        }
        .onPreferenceChange(PhoneDeckWidthKey.self) { cardWidth = $0 }
        // Background clipped separately so the open door / falling tape can overflow the top.
        .background(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "#2A2A2E"),
                            Color(hex: "#121214"),
                            Color(hex: "#0A0A0C")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                }
                .padding(.top, 36)
        }
        .shadow(color: .black.opacity(0.35), radius: 16, y: 8)
        .padding(.top, 28)
        .onAppear {
            guard !didAutoLoad else { return }
            didAutoLoad = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                insertTape(thenPlay: false)
            }
        }
        .onChange(of: title) { _, _ in
            reseatForNewTape()
        }
    }

    // MARK: - Controls

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#E8C547"), Color(hex: "#3DDC84")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(6, geo.size.width * min(max(progress, 0), 1)))
            }
        }
        .frame(height: 5)
    }

    private var playButton: some View {
        Button(action: handlePlayTap) {
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
        .disabled(isAnimating)
    }

    private func transportButton(_ icon: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
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
        .disabled(isAnimating)
    }

    // MARK: - Animation

    private func flashReel(_ motion: CassetteReelMotion, action: @escaping () -> Void) {
        guard deckPhase == .loaded else {
            insertTape(thenPlay: true)
            return
        }
        VintagePlayerAnimator.flashReel(
            motion: motion,
            setMotion: { reelOverride = $0 },
            then: action
        )
    }

    private func handlePlayTap() {
        if deckPhase == .loaded {
            onPlay()
        } else if !isAnimating {
            insertTape(thenPlay: true)
        }
    }

    private func replayInsert() {
        guard !isAnimating else { return }
        isAnimating = true
        reelOverride = nil
        if deckPhase == .loaded || deckPhase == .doorClosing {
            VintagePlayerAnimator.eject(
                update: { deckPhase = $0 },
                onComplete: {
                    VintagePlayerAnimator.insert(
                        update: { deckPhase = $0 },
                        onComplete: { isAnimating = false }
                    )
                }
            )
        } else {
            isAnimating = false
            insertTape(thenPlay: false)
        }
    }

    private func insertTape(thenPlay: Bool) {
        guard !isAnimating else { return }
        if deckPhase == .loaded {
            if thenPlay {
                if let onEnsurePlaying { onEnsurePlaying() } else { onPlay() }
            }
            return
        }

        isAnimating = true
        VintagePlayerAnimator.insert(
            update: { deckPhase = $0 },
            onComplete: {
                isAnimating = false
                if thenPlay {
                    if let onEnsurePlaying { onEnsurePlaying() } else { onPlay() }
                }
            }
        )
    }

    private func ejectTape() {
        guard !isAnimating, deckPhase == .loaded || deckPhase == .doorClosing else { return }
        isAnimating = true
        reelOverride = nil
        VintagePlayerAnimator.eject(
            update: { deckPhase = $0 },
            onComplete: { isAnimating = false }
        )
    }

    private func reseatForNewTape() {
        guard !isAnimating else { return }
        isAnimating = true
        reelOverride = nil
        VintagePlayerAnimator.eject(
            update: { deckPhase = $0 },
            onComplete: {
                VintagePlayerAnimator.insert(
                    update: { deckPhase = $0 },
                    onComplete: { isAnimating = false }
                )
            }
        )
    }
}

private struct PhoneDeckWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 360
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
