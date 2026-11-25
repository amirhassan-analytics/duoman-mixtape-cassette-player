//
//  NowPlayingBar.swift
//  mixtape
//

import SwiftUI
import UIKit

struct NowPlayingBar: View {

    @EnvironmentObject private var playback: PlaybackService

    var body: some View {
        if let mixtape = playback.currentMixtape, let item = playback.currentItem {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.metallicGradient)
                    if let image = mixtape.labelUIImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Image(systemName: "opticaldisc.fill")
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                .frame(width: 42, height: 42)
                .clipped()

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                    Text(mixtape.title)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.12))
                            Capsule()
                                .fill(AppTheme.accent)
                                .frame(width: geo.size.width * playback.progress)
                        }
                    }
                    .frame(height: 3)
                }

                Button {
                    playback.previous()
                } label: {
                    Image(systemName: "backward.fill")
                        .foregroundStyle(AppTheme.ink.opacity(0.85))
                        .frame(width: 32, height: 32)
                }
                .sportsClick(.mechanica)

                Button {
                    playback.toggle()
                } label: {
                    Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill")
                        .foregroundStyle(Color(hex: "#121214"))
                        .frame(width: 36, height: 36)
                        .background(AppTheme.accent)
                        .clipShape(Circle())
                }
                .sportsClick(.hard)

                Button {
                    playback.next()
                } label: {
                    Image(systemName: "forward.fill")
                        .foregroundStyle(AppTheme.ink.opacity(0.85))
                        .frame(width: 32, height: 32)
                }
                .sportsClick(.mechanica)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppTheme.surface.opacity(0.95))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 14)
            .padding(.bottom, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
