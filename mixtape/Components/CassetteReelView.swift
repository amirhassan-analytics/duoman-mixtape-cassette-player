//
//  CassetteReelView.swift
//  mixtape
//
//  Spinning cassette hub — play / pause / rewind / fast-forward.
//

import SwiftUI

struct CassetteReelView: View {

    var isPlaying: Bool
    var accent: Color = AppTheme.accent
    /// How much brown magnetic tape is wound on this reel (0...1).
    var woundAmount: Double = 0.55
    /// Optional explicit motion; when nil, derived from `isPlaying`.
    var motion: CassetteReelMotion? = nil

    private var wound: Double { min(max(woundAmount, 0.1), 0.92) }

    private var activeMotion: CassetteReelMotion {
        motion ?? (isPlaying ? .play : .stopped)
    }

    var body: some View {
        let spinning = activeMotion.isSpinning
        let rpm = activeMotion.degreesPerSecond

        return TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !spinning)) { context in
            let angle = spinning
                ? context.date.timeIntervalSinceReferenceDate * rpm
                : 18.0

            ZStack {
                // Magnetic tape pack
                Circle()
                    .stroke(
                        Color(hex: "#2A1A10"),
                        lineWidth: 5 + CGFloat(wound) * 7
                    )
                    .padding(3)

                Circle()
                    .stroke(
                        Color(hex: "#5C3D24").opacity(0.85),
                        lineWidth: 2 + CGFloat(wound) * 3
                    )
                    .padding(5)

                // Metal hub
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white,
                                Color(hex: "#C4C4CC"),
                                Color(hex: "#3A3842")
                            ],
                            center: .topLeading,
                            startRadius: 1,
                            endRadius: 22
                        )
                    )
                    .padding(8 + CGFloat(wound) * 2)

                Circle()
                    .fill(Color(hex: "#121014"))
                    .padding(11 + CGFloat(wound) * 2)

                ForEach(0..<6, id: \.self) { index in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#EEEFF4"), Color(hex: "#8A8A96")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2.6, height: 8)
                        .offset(y: -6.5)
                        .rotationEffect(.degrees(Double(index) * 60))
                }

                Circle()
                    .fill(accent)
                    .frame(width: 5, height: 5)
                    .shadow(
                        color: accent.opacity(spinning ? 0.9 : 0.25),
                        radius: spinning ? 4 : 0
                    )
            }
            .overlay {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.65), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .rotationEffect(.degrees(angle))
        }
    }
}
