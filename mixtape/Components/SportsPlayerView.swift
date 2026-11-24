//
//  SportsPlayerView.swift
//  mixtape
//

import SwiftUI

struct SportsPlayerView: View {

    var title: String
    var isPlaying: Bool
    var progress: Double
    var onPlay: () -> Void
    var onStop: () -> Void
    var onPrev: () -> Void
    var onNext: () -> Void

    @State private var drag: CGSize = .zero
    @State private var breathe = false
    @State private var pulse = false

    private var tiltX: Double { Double(-drag.height / 28) - 3 + (breathe ? -1 : 1) }
    private var tiltY: Double { Double(drag.width / 28) + 2 + (breathe ? 1 : -1) }

    var body: some View {
        ZStack(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "#FFE56A"),
                            AppTheme.yellow,
                            AppTheme.yellowDeep
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.55), lineWidth: 1.2)
                }
                .shadow(color: AppTheme.yellow.opacity(isPlaying ? 0.45 : 0.2), radius: isPlaying ? 22 : 12, y: 8)

            HStack {
                Spacer()
                Rectangle()
                    .fill(AppTheme.sportsBlue)
                    .frame(width: 26)
                    .overlay {
                        Text("STEREO")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(90))
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))

            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ALL WEATHER")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.2)
                            .foregroundStyle(AppTheme.ink.opacity(0.7))
                        Text("SPORTS")
                            .font(.system(size: 26, weight: .black))
                            .italic()
                            .foregroundStyle(AppTheme.sportsBlue)
                    }
                    Spacer()

                    Circle()
                        .fill(isPlaying ? Color.green : AppTheme.sportsRed)
                        .frame(width: 10, height: 10)
                        .shadow(color: (isPlaying ? Color.green : AppTheme.sportsRed).opacity(0.8), radius: isPlaying ? 6 : 0)
                        .scaleEffect(pulse && isPlaying ? 1.25 : 1)
                        .padding(.trailing, 28)
                }

                circularWindow

                HStack(spacing: 18) {
                    controlButton("backward.fill", size: 36, action: onPrev)
                    controlButton(isPlaying ? "stop.fill" : "play.fill", size: 54, primary: true) {
                        if isPlaying { onStop() } else { onPlay() }
                    }
                    controlButton("forward.fill", size: 36, action: onNext)
                }
                .padding(.trailing, 8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .padding(.trailing, 18)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 330)
        .rotation3DEffect(.degrees(tiltX), axis: (x: 1, y: 0, z: 0), perspective: 0.7)
        .rotation3DEffect(.degrees(tiltY), axis: (x: 0, y: 1, z: 0), perspective: 0.7)
        .offset(y: breathe ? -2.5 : 2.5)
        .gesture(
            DragGesture(minimumDistance: 6)
                .onChanged { value in
                    drag = CGSize(
                        width: min(max(value.translation.width, -45), 45),
                        height: min(max(value.translation.height, -45), 45)
                    )
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        drag = .zero
                    }
                }
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                breathe = true
            }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .accessibilityLabel("Sports player \(title)")
    }

    private var circularWindow: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white, AppTheme.chrome, AppTheme.chromeDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 184, height: 184)
                .shadow(color: .black.opacity(0.22), radius: 8, y: 4)

            ForEach(0..<6, id: \.self) { i in
                Circle()
                    .fill(Color(hex: "#9A9A9A"))
                    .frame(width: 7, height: 7)
                    .offset(y: -86)
                    .rotationEffect(.degrees(Double(i) * 60))
            }

            Circle()
                .stroke(AppTheme.sportsRed, lineWidth: 4)
                .frame(width: 158, height: 158)

            Circle()
                .fill(Color.black)
                .frame(width: 142, height: 142)
                .overlay {
                    // Soft radar sweep when playing
                    if isPlaying {
                        AngularGradient(
                            colors: [.clear, AppTheme.yellow.opacity(0.25), .clear],
                            center: .center
                        )
                        .rotationEffect(.degrees(progress * 360))
                        .clipShape(Circle())
                    }
                }

            Circle()
                .trim(from: 0, to: min(max(progress, 0.02), 1))
                .stroke(AppTheme.yellow, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))

            Capsule()
                .fill(Color.white)
                .frame(width: 2.5, height: 72)
                .shadow(color: .white.opacity(0.5), radius: 2)
                .rotationEffect(.degrees(isPlaying ? (progress * 40 - 20) : -8))
                .animation(.easeOut(duration: 0.2), value: progress)

            VStack(spacing: 4) {
                Spacer()
                Text(isPlaying ? "PLAY" : "READY")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white.opacity(0.55))
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.yellow)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 22)
            }
            .frame(width: 142, height: 142)
        }
    }

    private func controlButton(
        _ icon: String,
        size: CGFloat,
        primary: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: primary ? 18 : 13, weight: .bold))
                .foregroundStyle(primary ? AppTheme.ink : .white)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(primary ? AppTheme.yellow : Color.black.opacity(0.82))
                        .shadow(color: .black.opacity(0.25), radius: primary ? 8 : 4, y: 3)
                )
                .scaleEffect(primary && isPlaying && pulse ? 1.05 : 1)
        }
        .sportsClick(primary ? .hard : .mechanica)
    }
}
