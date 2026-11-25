//
//  MagneticTapeMeter.swift
//  mixtape
//
//  Compact Side A / Side B magnetic reels — 30:00 each.
//

import SwiftUI

struct MagneticTapeMeter: View {

    let mixtape: Mixtape
    var selectedSide: TapeSide
    var onSelect: (TapeSide) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Magnetic tape")
                    .font(AppTheme.title(14, weight: .heavy))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Text("30 min each side")
                    .font(AppTheme.body(11, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            HStack(spacing: 8) {
                ForEach(TapeSide.allCases) { side in
                    Button {
                        onSelect(side)
                    } label: {
                        Text(side.label)
                            .font(AppTheme.body(13, weight: .bold))
                            .foregroundStyle(
                                selectedSide == side
                                    ? Color(hex: "#121214")
                                    : AppTheme.secondaryText
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(
                                selectedSide == side
                                    ? AnyShapeStyle(AppTheme.accentGradient)
                                    : AnyShapeStyle(AppTheme.surfaceLight)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            sideBar(side: .a)
            sideBar(side: .b)
        }
        .padding(14)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.3), radius: 10, y: 3)
    }

    private func sideBar(side: TapeSide) -> some View {
        let used = mixtape.usedSeconds(on: side)
        let left = mixtape.remainingSeconds(on: side)
        let fraction = TapeCapacity.usedFraction(used)

        return VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(side.label)
                    .font(AppTheme.body(12, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Text("\(TapeCapacity.format(used)) / 30:00")
                    .font(AppTheme.body(11, weight: .semibold))
                    .foregroundStyle(fraction > 0.92 ? AppTheme.recordingRed : AppTheme.secondaryText)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: fraction > 0.92
                                    ? [AppTheme.recordingRed, Color(hex: "#B91C1C")]
                                    : [Color(hex: "#5A4A20"), AppTheme.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geo.size.width * fraction, fraction > 0 ? 6 : 0))
                }
            }
            .frame(height: 8)

            Text(left < 1 ? "Side full" : "\(TapeCapacity.format(left)) left on reel")
                .font(AppTheme.body(10))
                .foregroundStyle(AppTheme.secondaryText)
        }
    }
}
