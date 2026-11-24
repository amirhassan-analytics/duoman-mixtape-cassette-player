//
//  VintageTransparentCassette.swift
//  mixtape
//
//  Clear-shell cassette with a glass window and dual spinning reels.
//

import SwiftUI

struct VintageTransparentCassette: View {

    var title: String
    var side: TapeSide = .a
    var labelImage: UIImage?
    var reelMotion: CassetteReelMotion = .stopped
    var tapeFill: Double = 0.45
    var compact: Bool = false

    var body: some View {
        GeometryReader { geo in
            let w = max(geo.size.width, 1)
            let h = max(geo.size.height, 1)

            ZStack {
                // Clear plastic shell
                RoundedRectangle(cornerRadius: compact ? 10 : 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.28),
                                Color(hex: "#B8B4AE").opacity(0.22),
                                Color(hex: "#6E6A64").opacity(0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background {
                        RoundedRectangle(cornerRadius: compact ? 10 : 14, style: .continuous)
                            .fill(.ultraThinMaterial.opacity(0.55))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: compact ? 10 : 14, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.9),
                                        .white.opacity(0.2),
                                        .black.opacity(0.35)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.4
                            )
                    }

                // Screws
                ForEach(0..<4, id: \.self) { i in
                    screw
                        .position(
                            x: i % 2 == 0 ? 12 : w - 12,
                            y: i < 2 ? 12 : h - 12
                        )
                }

                VStack(spacing: h * 0.04) {
                    // Paper label
                    labelStrip(width: w, height: h * (compact ? 0.28 : 0.3))
                        .padding(.horizontal, w * 0.08)
                        .padding(.top, h * 0.07)

                    // Transparent window + reels
                    window(width: w, height: h * (compact ? 0.38 : 0.36))
                        .padding(.horizontal, w * 0.12)

                    HStack {
                        Text(reelMotion == .play ? "● PLAY" : "TYPE I")
                            .foregroundStyle(reelMotion == .play ? Color(hex: "#E8C547") : .black.opacity(0.4))
                        Spacer()
                        Text(side.label.uppercased())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.black.opacity(0.12)))
                            .foregroundStyle(Color.black.opacity(0.55))
                    }
                    .font(.system(size: max(7, w * 0.028), weight: .bold, design: .rounded))
                    .padding(.horizontal, w * 0.09)
                    .padding(.bottom, h * 0.05)
                }
            }
        }
        .aspectRatio(1.62, contentMode: .fit)
    }

    private func labelStrip(width w: CGFloat, height h: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color(hex: "#F4EFE6"))
                .overlay {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 0.8)
                }

            if let labelImage {
                Image(uiImage: labelImage)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .padding(2)
            } else {
                VStack(spacing: 3) {
                    Text(title.uppercased())
                        .font(.system(size: max(11, w * 0.048), weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: "#1A1816"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    Text("CUSTOM MIX")
                        .font(.system(size: max(7, w * 0.024), weight: .bold, design: .rounded))
                        .tracking(1.4)
                        .foregroundStyle(Color.black.opacity(0.4))
                }
                .padding(.horizontal, 8)
            }
        }
        .frame(height: h)
    }

    private func window(width w: CGFloat, height h: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#0C0B0E"), Color(hex: "#1E1B22")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                }

            // Tape path between reels
            Capsule()
                .fill(Color(hex: "#1A1512"))
                .frame(height: 6)
                .padding(.horizontal, w * 0.16)
                .offset(y: h * 0.08)
                .overlay {
                    Capsule()
                        .fill(Color(hex: "#E8C547").opacity(reelMotion.isSpinning ? 0.4 : 0.1))
                        .frame(height: 2.5)
                        .padding(.horizontal, w * 0.2)
                        .offset(y: h * 0.08)
                }

            HStack(spacing: w * 0.16) {
                CassetteReelView(
                    isPlaying: false,
                    accent: Color(hex: "#E8C547"),
                    woundAmount: min(max(tapeFill, 0.12), 0.92),
                    motion: reelMotion
                )
                .frame(width: w * 0.14, height: w * 0.14)

                CassetteReelView(
                    isPlaying: false,
                    accent: Color(hex: "#E8C547"),
                    woundAmount: max(0.12, 1 - tapeFill),
                    motion: reelMotion
                )
                .frame(width: w * 0.14, height: w * 0.14)
            }

            // Glass glare
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.2), .clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .allowsHitTesting(false)
        }
        .frame(height: h)
    }

    private var screw: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#D8D4CE"), Color(hex: "#6F6A64")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 7, height: 7)
            Capsule()
                .fill(Color.black.opacity(0.45))
                .frame(width: 4.5, height: 1.1)
        }
    }
}
