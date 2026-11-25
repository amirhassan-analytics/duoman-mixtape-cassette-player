//
//  DuoManMusicBox3D.swift
//  mixtape
//
//  3D Walkman music-box: lid opens → cassette drops onto spindles → lid closes.
//

import SwiftUI

struct DuoManMusicBox3D: View {

    var phase: DuoManPhase
    var title: String
    var side: TapeSide
    var labelImage: UIImage?
    var isPlaying: Bool
    var tapeFill: Double
    var showInsertingTape: Bool

    /// 0 = fully open, 1 = fully closed
    private var lidClosed: Double {
        switch phase {
        case .open: return 0
        case .inserting: return 0.08
        case .closing: return 0.72
        case .closed: return 1
        }
    }

    /// 0 = floating above bay, 1 = seated on spindles
    private var cassetteSeat: Double {
        switch phase {
        case .open: return showInsertingTape ? 0.15 : 0
        case .inserting: return 0.85
        case .closing, .closed: return 1
        }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Desk shadow
                Ellipse()
                    .fill(Color.black.opacity(0.28))
                    .frame(width: w * 0.78, height: 28)
                    .blur(radius: 10)
                    .offset(y: h * 0.42)

                // Music box body (perspective)
                musicBoxBody(width: w, height: h)
                    .rotation3DEffect(
                        .degrees(-8 + lidClosed * 4),
                        axis: (x: 1, y: 0, z: 0),
                        perspective: 0.65
                    )
                    .rotation3DEffect(
                        .degrees(phase == .closed ? -2 : 6),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.55
                    )
            }
            .frame(width: w, height: h)
        }
        .animation(.spring(response: 0.85, dampingFraction: 0.82), value: phase)
        .animation(.easeInOut(duration: 0.7), value: cassetteSeat)
    }

    private func musicBoxBody(width w: CGFloat, height h: CGFloat) -> some View {
        let boxW = min(w * 0.92, 360)
        let boxH = min(h * 0.78, 260)

        return ZStack {
            // Bottom shell
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    AppTheme.metallicGradient
                )
                .frame(width: boxW, height: boxH)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1.4)
                }
                .shadow(color: .black.opacity(0.45), radius: 18, y: 10)

            // Inner bay cavity
            bayCavity(boxW: boxW, boxH: boxH)

            // Cassette travelling into bay
            if cassetteSeat > 0.02 || phase != .open {
                cassetteInBay(boxW: boxW, boxH: boxH)
            }

            // Hinged lid
            lid(boxW: boxW, boxH: boxH)

            // Brand plate
            Text("MIXTAPE")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundStyle(AppTheme.ink.opacity(0.55))
                .offset(y: boxH * 0.42)
        }
    }

    private func bayCavity(boxW: CGFloat, boxH: CGFloat) -> some View {
        let cavityW = boxW * 0.86
        let cavityH = boxH * 0.58

        return ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "#1A1714"),
                            Color(hex: "#0C0B0A"),
                            Color(hex: "#22201C")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: cavityW, height: cavityH)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                }

            // Spindle posts
            HStack(spacing: cavityW * 0.28) {
                spindle
                spindle
            }
            .offset(y: cavityH * 0.06)

            // Head / pinch rollers hint
            Capsule()
                .fill(Color(hex: "#3A3732"))
                .frame(width: cavityW * 0.42, height: 10)
                .overlay {
                    Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                }
                .offset(y: cavityH * 0.28)

            if phase == .open && cassetteSeat < 0.2 {
                Text("CASSETTE BAY")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(Color.white.opacity(0.35))
                    .offset(y: -cavityH * 0.32)
            }
        }
        .offset(y: -boxH * 0.04)
        .opacity(1 - lidClosed * 0.15)
    }

    private var spindle: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "#C8C4BC"), Color(hex: "#6A6660"), Color(hex: "#2A2824")],
                        center: .center,
                        startRadius: 2,
                        endRadius: 22
                    )
                )
                .frame(width: 44, height: 44)
                .overlay {
                    Circle().stroke(Color.white.opacity(0.25), lineWidth: 1)
                }

            Circle()
                .fill(Color(hex: "#1A1816"))
                .frame(width: 14, height: 14)

            ForEach(0..<6, id: \.self) { i in
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 2, height: 8)
                    .offset(y: -16)
                    .rotationEffect(.degrees(Double(i) * 60))
            }
        }
        .rotationEffect(.degrees(isPlaying && phase == .closed ? 360 : 0))
        .animation(
            isPlaying && phase == .closed
                ? .linear(duration: 2.4).repeatForever(autoreverses: false)
                : .default,
            value: isPlaying && phase == .closed
        )
    }

    private func cassetteInBay(boxW: CGFloat, boxH: CGFloat) -> some View {
        let lift = (1 - cassetteSeat) * 90
        let scale = 0.72 + cassetteSeat * 0.18
        let tilt = (1 - cassetteSeat) * -28

        return RealisticCassetteView(
            title: title,
            accent: AppTheme.ink,
            shellTint: Color(hex: "#2A2A2E"),
            labelImage: labelImage,
            isPlaying: isPlaying && phase == .closed,
            interactive3D: false,
            side: side,
            tapeFill: tapeFill,
            solidShell: true
        )
        .frame(width: boxW * 0.78, height: boxH * 0.48)
        .scaleEffect(scale)
        .offset(y: -boxH * 0.06 - lift)
        .rotation3DEffect(.degrees(tilt), axis: (x: 1, y: 0, z: 0), perspective: 0.7)
        .opacity(0.35 + cassetteSeat * 0.65)
        .shadow(color: .black.opacity(0.45 * cassetteSeat), radius: 12, y: 8)
        .allowsHitTesting(false)
    }

    private func lid(boxW: CGFloat, boxH: CGFloat) -> some View {
        let lidH = boxH * 0.55
        // Open lid flips up around top hinge (rotationX ~ -110 when open)
        let openAngle = -110.0
        let angle = openAngle + (lidClosed * -openAngle)

        return ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "#4A4A50"),
                            Color(hex: "#222226"),
                            Color(hex: "#101012")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: boxW * 0.94, height: lidH)
                .overlay {
                    // Window in lid
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: "#12110F").opacity(0.55 + lidClosed * 0.35))
                        .frame(width: boxW * 0.62, height: lidH * 0.42)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        }
                        .overlay {
                            if lidClosed > 0.55 {
                                Text(side.label.uppercased())
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                        .offset(y: lidH * 0.06)
                }
                .overlay(alignment: .bottom) {
                    // Chrome latch
                    Capsule()
                        .fill(AppTheme.chromeGradient)
                        .frame(width: 54, height: 10)
                        .padding(.bottom, 10)
                }
                .shadow(color: .black.opacity(0.35 * (1 - lidClosed)), radius: 16, y: -6)
        }
        .frame(width: boxW * 0.94, height: lidH, alignment: .top)
        .rotation3DEffect(
            .degrees(angle),
            axis: (x: 1, y: 0, z: 0),
            anchor: .top,
            perspective: 0.85
        )
        .offset(y: -boxH * 0.36)
        .opacity(phase == .closed ? 0.92 : 1)
    }
}

/// Compact bay-only panel for the open Duo right screen.
struct DuoManCassetteBayPanel: View {
    var phase: DuoManPhase
    var title: String
    var side: TapeSide
    var labelImage: UIImage?
    var isPlaying: Bool
    var tapeFill: Double
    var hint: String

    var body: some View {
        VStack(spacing: 14) {
            Text(hint)
                .font(AppTheme.body(13, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())

            DuoManMusicBox3D(
                phase: phase,
                title: title,
                side: side,
                labelImage: labelImage,
                isPlaying: isPlaying,
                tapeFill: tapeFill,
                showInsertingTape: phase != .open
            )
            .frame(height: 240)

            Text(phase.statusLine)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(AppTheme.accent)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color(hex: "#1E1C19"), Color(hex: "#0A0908")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
