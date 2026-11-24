//
//  RealisticCassetteView.swift
//  mixtape
//
//  Original clear-plastic 3D cassette (unchanged look).
//  Side A / Side B is only a badge — magnetic length comes from songs.
//

import SwiftUI

struct RealisticCassetteView: View {

    var title: String
    var accent: Color
    var shellTint: Color
    var labelImage: UIImage?
    var isPlaying: Bool
    var interactive3D: Bool = true
    var side: TapeSide = .a
    var tapeFill: Double = 0.35
    /// Solid metallic shell (DUOMAN deck).
    var solidShell: Bool = false

    @State private var drag: CGSize = .zero
    @State private var breathe = false
    @State private var shine = false

    private var tiltX: Double {
        let touch = interactive3D ? Double(-drag.height / 18) : 0
        return touch - 10 + (breathe ? -1.5 : 1.5)
    }

    private var tiltY: Double {
        let touch = interactive3D ? Double(drag.width / 18) : 0
        return touch + 12 + (breathe ? 1.8 : -1.2)
    }

    var body: some View {
        ZStack {
            Ellipse()
                .fill(accent.opacity(isPlaying ? 0.35 : 0.18))
                .blur(radius: 28)
                .frame(height: 40)
                .offset(y: 55)
                .scaleEffect(isPlaying ? 1.15 : 1)

            cassetteStack
                .rotation3DEffect(.degrees(tiltX), axis: (x: 1, y: 0, z: 0), perspective: 0.55)
                .rotation3DEffect(.degrees(tiltY), axis: (x: 0, y: 1, z: 0), perspective: 0.55)
                .offset(y: breathe ? -4 : 4)
                .shadow(color: .black.opacity(0.35), radius: 18, y: 16)
                .shadow(color: accent.opacity(0.25), radius: isPlaying ? 24 : 10, y: 8)
        }
        .aspectRatio(1.6, contentMode: .fit)
        .gesture(dragGesture, including: interactive3D ? .all : .none)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                breathe = true
            }
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                shine = true
            }
        }
        .accessibilityLabel("3D cassette \(title)")
    }

    private var cassetteStack: some View {
        GeometryReader { geo in
            let w = max(geo.size.width, 1)
            let h = max(geo.size.height, 1)

            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(hex: "#2A2622").opacity(0.55))
                    .offset(x: 5, y: 7)
                    .blur(radius: 0.4)

                // Shell — metallic for deck, clear plastic elsewhere
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        solidShell
                            ? LinearGradient(
                                colors: [
                                    Color(hex: "#3A3A3E"),
                                    shellTint,
                                    Color(hex: "#0C0C0E")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [
                                    Color.white.opacity(0.72),
                                    shellTint.opacity(0.55),
                                    Color(hex: "#8E8680").opacity(0.45)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .background {
                        if !solidShell {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.95),
                                        .white.opacity(0.2),
                                        .black.opacity(0.25)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.6
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 13)
                            .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                            .padding(4)
                    }
                    .overlay {
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.45), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(width: w * 0.2)
                        .rotationEffect(.degrees(20))
                        .offset(x: shine ? w * 0.75 : -w * 0.55)
                        .blendMode(.screen)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .allowsHitTesting(false)
                    }

                ForEach(0..<4, id: \.self) { index in
                    metalScrew
                        .position(
                            x: index % 2 == 0 ? 15 : w - 15,
                            y: index < 2 ? 15 : h - 15
                        )
                }

                VStack(spacing: h * 0.025) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(Color.black.opacity(0.18))
                            .offset(y: 1.5)

                        RoundedRectangle(cornerRadius: 9)
                            .fill(Color(hex: "#F7F1E6"))
                            .overlay {
                                RoundedRectangle(cornerRadius: 9)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.black.opacity(0.2), .white.opacity(0.5)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                            }

                        if let labelImage {
                            Image(uiImage: labelImage)
                                .resizable()
                                .scaledToFill()
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .padding(2)
                        } else {
                            VStack(spacing: 4) {
                                Text(title.uppercased())
                                    .font(.system(size: max(13, w * 0.052), weight: .black))
                                    .foregroundStyle(accent)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Text("CUSTOM MIX")
                                    .font(.system(size: max(7, w * 0.025), weight: .bold))
                                    .tracking(1.5)
                                    .foregroundStyle(accent.opacity(0.7))
                            }
                            .padding(.horizontal, 10)
                        }
                    }
                    .frame(height: h * 0.3)
                    .padding(.horizontal, w * 0.08)
                    .padding(.top, h * 0.075)
                    .shadow(color: .black.opacity(0.15), radius: 3, y: 2)

                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "#0D0C10"),
                                        Color(hex: "#2A252E")
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            }
                            .shadow(color: .black.opacity(0.4), radius: 4, y: 2)

                        // Magnetic tape path — fills as the side has more songs
                        Capsule()
                            .fill(Color(hex: "#1A1512"))
                            .frame(height: 7)
                            .padding(.horizontal, w * 0.18)
                            .offset(y: h * 0.06)
                            .overlay {
                                Capsule()
                                    .fill(accent.opacity(isPlaying ? 0.45 : 0.12))
                                    .frame(height: 3)
                                    .padding(.horizontal, w * 0.22)
                                    .offset(y: h * 0.06)
                            }

                        HStack(spacing: w * 0.15) {
                            CassetteReelView(
                                isPlaying: isPlaying,
                                accent: accent,
                                woundAmount: min(max(tapeFill, 0.1), 0.95)
                            )
                                .frame(width: w * 0.145, height: w * 0.145)
                                .shadow(color: accent.opacity(0.35), radius: isPlaying ? 8 : 0)

                            CassetteReelView(
                                isPlaying: isPlaying,
                                accent: accent,
                                woundAmount: max(0.12, 1 - tapeFill)
                            )
                                .frame(width: w * 0.145, height: w * 0.145)
                                .shadow(color: accent.opacity(0.35), radius: isPlaying ? 8 : 0)
                        }

                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.18), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .center
                                )
                            )
                            .allowsHitTesting(false)
                    }
                    .frame(height: h * 0.34)
                    .padding(.horizontal, w * 0.12)

                    HStack {
                        Text(isPlaying ? "● PLAYING" : "TYPE I NORMAL")
                            .foregroundStyle(isPlaying ? accent : Color.black.opacity(0.45))
                        Spacer()
                        Text(side.label.uppercased())
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(accent.opacity(0.2))
                                    .overlay(Capsule().stroke(accent.opacity(0.35), lineWidth: 0.8))
                            )
                            .foregroundStyle(accent)
                    }
                    .font(.system(size: max(7.5, w * 0.028), weight: .bold))
                    .padding(.horizontal, w * 0.09)
                    .padding(.bottom, h * 0.05)
                }
            }
        }
    }

    private var metalScrew: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#D8D4CE"), Color(hex: "#6F6A64")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 8, height: 8)
                .shadow(color: .black.opacity(0.35), radius: 1, y: 0.5)

            Capsule()
                .fill(Color.black.opacity(0.45))
                .frame(width: 5, height: 1.2)
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                drag = CGSize(
                    width: min(max(value.translation.width, -70), 70),
                    height: min(max(value.translation.height, -70), 70)
                )
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    drag = .zero
                }
            }
    }
}

