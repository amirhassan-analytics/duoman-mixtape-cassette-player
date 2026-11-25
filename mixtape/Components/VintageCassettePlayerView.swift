//
//  VintageCassettePlayerView.swift
//  mixtape
//
//  Real-device motion: door swings open to the RIGHT → cassette slides in from the RIGHT → latch.
//

import SwiftUI

struct VintageCassettePlayerView: View {

    var phase: VintagePlayerPhase
    var title: String
    var side: TapeSide = .a
    var labelImage: UIImage?
    var reelMotion: CassetteReelMotion = .stopped
    var tapeFill: Double = 0.45
    var progress: Double = 0
    var brand: String = "MIXTAPE"
    var showsOverlayLabels: Bool = true
    var compactLayout: Bool = false

    private var doorOpen: Double { phase.doorOpenAmount }
    private var seat: Double { phase.cassetteSeatAmount }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let bodyW = min(w * 0.86, compactLayout ? w * 0.88 : 360)
            let bodyH = min(h * 0.9, compactLayout ? h * 0.92 : 260)

            ZStack(alignment: .center) {
                Ellipse()
                    .fill(Color.black.opacity(0.28))
                    .frame(width: bodyW * 0.78, height: 18)
                    .blur(radius: 8)
                    .offset(y: bodyH * 0.48)

                // Cassette waiting / sliding from the RIGHT (outside the bay)
                if phase.showsCassette && seat < 0.98 {
                    approachingCassette(bodyW: bodyW, bodyH: bodyH)
                }

                chassis(width: bodyW, height: bodyH)

                // Door hinged on the RIGHT edge — swings open outward
                hingedDoor(width: bodyW, height: bodyH)
            }
            .frame(width: w, height: h)
            // Keep room on the right for open door + incoming tape
            .padding(.trailing, compactLayout ? 8 : 12)
        }
        .animation(.spring(response: 0.75, dampingFraction: 0.84), value: phase)
        .animation(.interactiveSpring(response: 0.7, dampingFraction: 0.8), value: seat)
        .animation(.easeInOut(duration: 0.6), value: doorOpen)
        .accessibilityLabel("Cassette deck \(phase.statusLabel)")
    }

    // MARK: - Chassis

    private func chassis(width: CGFloat, height: CGFloat) -> some View {
        let cavityW = width * 0.86
        let cavityH = height * 0.58

        return ZStack {
            RoundedRectangle(cornerRadius: compactLayout ? 16 : 20, style: .continuous)
                .fill(metallicFill)
                .frame(width: width, height: height)
                .overlay {
                    RoundedRectangle(cornerRadius: compactLayout ? 16 : 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.06),
                                    Color.black.opacity(0.55)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                }
                .shadow(color: .black.opacity(0.4), radius: 14, y: 10)

            HStack(spacing: 3) {
                ForEach(0..<16, id: \.self) { _ in
                    Capsule()
                        .fill(Color.black.opacity(0.5))
                        .frame(height: compactLayout ? 8 : 11)
                }
            }
            .padding(.horizontal, 18)
            .frame(width: width, height: height, alignment: .top)
            .padding(.top, 10)

            // Bay cavity — right edge is the load slot
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#0E0D0C"),
                                Color(hex: "#050504"),
                                Color(hex: "#161412")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                HStack(spacing: cavityW * 0.28) {
                    spindle(size: compactLayout ? 28 : 36)
                    spindle(size: compactLayout ? 28 : 36)
                }
                .offset(y: 4)
                .opacity(seat > 0.85 ? 0.25 : 0.95)

                Capsule()
                    .fill(Color(hex: "#2C2A26"))
                    .frame(width: cavityW * 0.36, height: 8)
                    .offset(y: cavityH * 0.32)

                if phase.showsCassette && seat > 0.2 {
                    seatedCassette(cavityW: cavityW, cavityH: cavityH)
                }

                if phase == .empty {
                    Text("LOAD FROM RIGHT →")
                        .font(.system(size: compactLayout ? 8 : 10, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(Color.white.opacity(0.28))
                }

                // Slot lip on the right of the bay
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#3A3A40"), Color(hex: "#1A1A1E")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 5, height: cavityH * 0.92)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 2)
            }
            .frame(width: cavityW, height: cavityH)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            }
            .offset(y: height * 0.02)

            if showsOverlayLabels {
                HStack {
                    Text(brand)
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(Color.white.opacity(0.45))
                    Spacer()
                    Text(phase.statusLabel)
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 16)
                .frame(width: width, height: height, alignment: .bottom)
                .padding(.bottom, 10)
            }
        }
    }

    // MARK: - Cassette from the right

    /// Tape held to the right of the bay, then slides left onto the spindles.
    private func approachingCassette(bodyW: CGFloat, bodyH: CGFloat) -> some View {
        let travel = (1 - seat) * (bodyW * 0.95 + 36)
        let scale = 0.7 + seat * 0.22
        // Slight yaw so it reads as sliding into a side slot
        let yaw = (1 - seat) * 18.0

        return VintageTransparentCassette(
            title: title,
            side: side,
            labelImage: labelImage,
            reelMotion: .stopped,
            tapeFill: tapeFill,
            compact: true
        )
        .frame(width: bodyW * 0.78, height: bodyH * 0.42)
        .scaleEffect(scale)
        .rotation3DEffect(.degrees(yaw), axis: (x: 0, y: 1, z: 0), perspective: 0.75)
        .offset(x: travel, y: bodyH * 0.02)
        .opacity(seat < 0.92 ? (0.35 + seat * 0.65) : 0)
        .allowsHitTesting(false)
        .zIndex(20)
    }

    private func seatedCassette(cavityW: CGFloat, cavityH: CGFloat) -> some View {
        let reveal = max(0, (seat - 0.2) / 0.8)

        return VintageTransparentCassette(
            title: title,
            side: side,
            labelImage: labelImage,
            reelMotion: phase == .loaded ? reelMotion : .stopped,
            tapeFill: tapeFill,
            compact: true
        )
        .frame(width: cavityW * 0.92, height: cavityH * 0.78)
        .scaleEffect(0.9 + reveal * 0.08)
        .opacity(reveal)
        // Enter from the right edge of the bay as it seats
        .offset(x: (1 - reveal) * (cavityW * 0.35))
        .allowsHitTesting(false)
    }

    // MARK: - Right-hinged door

    private func hingedDoor(width: CGFloat, height: CGFloat) -> some View {
        let doorW = width * 0.88
        let doorH = height * 0.52
        // Open outward to the right (around the trailing edge)
        let angle = 105.0 * doorOpen

        return ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "#55555C"),
                            Color(hex: "#2A2A30"),
                            Color(hex: "#121216")
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(hex: "#0A0A0C").opacity(0.35 + (1 - doorOpen) * 0.45))
                        .frame(width: doorW * 0.58, height: doorH * 0.55)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        }
                        .overlay {
                            if doorOpen < 0.12 && phase == .loaded {
                                Text(title)
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.white.opacity(0.55))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .padding(.horizontal, 8)
                            }
                        }
                }
                .overlay(alignment: .leading) {
                    // Latch on the left (free edge)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.white, Color(hex: "#A0A0A8"), Color(hex: "#585860")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 7, height: 40)
                        .padding(.leading, 8)
                }
                .overlay(alignment: .trailing) {
                    // Vertical hinge bar on the right
                    Capsule()
                        .fill(Color(hex: "#8A8A92"))
                        .frame(width: 4, height: doorH * 0.75)
                        .padding(.trailing, 4)
                }
        }
        .frame(width: doorW, height: doorH)
        .shadow(color: .black.opacity(0.4 * doorOpen), radius: 14, x: 8)
        .rotation3DEffect(
            .degrees(angle),
            axis: (x: 0, y: 1, z: 0),
            anchor: .trailing,
            perspective: 0.85
        )
        .offset(y: height * 0.02)
        .zIndex(30)
        .allowsHitTesting(false)
    }

    // MARK: - Bits

    private func spindle(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "#D0CCC4"),
                            Color(hex: "#6A6660"),
                            Color(hex: "#2A2824")
                        ],
                        center: .center,
                        startRadius: 1,
                        endRadius: size * 0.5
                    )
                )
                .frame(width: size, height: size)
            Circle()
                .fill(Color(hex: "#141210"))
                .frame(width: size * 0.28, height: size * 0.28)
            ForEach(0..<6, id: \.self) { i in
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 2, height: size * 0.22)
                    .offset(y: -size * 0.32)
                    .rotationEffect(.degrees(Double(i) * 60))
            }
        }
        .rotationEffect(.degrees(reelMotion.isSpinning && phase == .loaded ? 360 : 0))
        .animation(
            reelMotion.isSpinning && phase == .loaded
                ? .linear(duration: 2.2).repeatForever(autoreverses: false)
                : .default,
            value: reelMotion.isSpinning && phase == .loaded
        )
    }

    private var metallicFill: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "#3A3A3E"),
                Color(hex: "#1A1A1C"),
                Color(hex: "#0C0C0E"),
                Color(hex: "#242428")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var statusColor: Color {
        switch phase {
        case .loaded where reelMotion == .play:
            return Color(hex: "#3DDC84")
        case .inserting, .doorOpening, .doorClosing, .ejecting:
            return Color(hex: "#E8C547")
        default:
            return Color.white.opacity(0.45)
        }
    }
}

// MARK: - Bay panel (Duo)

struct VintagePlayerBayPanel: View {
    var phase: VintagePlayerPhase
    var title: String
    var side: TapeSide
    var labelImage: UIImage?
    var reelMotion: CassetteReelMotion
    var tapeFill: Double
    var progress: Double
    var hint: String

    var body: some View {
        VStack(spacing: 12) {
            Text(hint)
                .font(AppTheme.body(12, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())

            VintageCassettePlayerView(
                phase: phase,
                title: title,
                side: side,
                labelImage: labelImage,
                reelMotion: reelMotion,
                tapeFill: tapeFill,
                progress: progress,
                showsOverlayLabels: true,
                compactLayout: false
            )
            .frame(height: 260)

            Text(phase.statusLabel)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(Color(hex: "#E8C547"))
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color(hex: "#1A1917"), Color(hex: "#080807")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
