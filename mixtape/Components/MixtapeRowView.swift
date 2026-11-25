//
//  MixtapeRowView.swift
//  mixtape
//
//  Library row — black metallic cassette thumb.
//

import SwiftUI

struct MixtapeRowView: View {

    let mixtape: Mixtape
    var isFavorite: Bool = false

    private var totalSeconds: TimeInterval {
        mixtape.usedSeconds(on: .a) + mixtape.usedSeconds(on: .b)
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppTheme.metallicGradient)
                HStack(spacing: 6) {
                    Circle().fill(AppTheme.accent.opacity(0.85)).frame(width: 10, height: 10)
                    Circle().fill(AppTheme.accent.opacity(0.85)).frame(width: 10, height: 10)
                }
            }
            .frame(width: 52, height: 36)
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.35), radius: 4, y: 2)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(mixtape.title)
                        .font(AppTheme.title(16, weight: .heavy))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                    if isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.recordingRed)
                    }
                }

                Text("\(mixtape.songCount) tracks · \(TapeCapacity.format(totalSeconds))")
                    .font(AppTheme.body(12))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer(minLength: 4)

            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText.opacity(0.7))
                .frame(width: 28, height: 28)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
    }
}
