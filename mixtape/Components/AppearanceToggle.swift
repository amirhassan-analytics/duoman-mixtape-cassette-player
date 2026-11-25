//
//  AppearanceToggle.swift
//  mixtape
//
//  Dark / Light mode toggle control.
//

import SwiftUI

struct AppearanceToggle: View {

    @EnvironmentObject private var appearance: AppearanceStore

    var compact: Bool = false

    var body: some View {
        if compact {
            Button {
                appearance.toggle()
            } label: {
                Image(systemName: appearance.isDark ? "moon.fill" : "sun.max.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(appearance.isDark ? AppTheme.accent : Color(hex: "#C4A020"))
                    .frame(width: 36, height: 36)
                    .background(AppTheme.surfaceLight)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(appearance.isDark ? "Switch to light mode" : "Switch to dark mode")
        } else {
            HStack(spacing: 12) {
                Image(systemName: appearance.isDark ? "moon.fill" : "sun.max.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Appearance")
                        .font(AppTheme.title(15, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                    Text(appearance.isDark ? "Dark metallic" : "Light mode")
                        .font(AppTheme.body(12))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { appearance.isDark },
                    set: { appearance.setDark($0) }
                ))
                .labelsHidden()
                .tint(AppTheme.accent)
            }
            .padding(16)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            }
        }
    }
}

/// Segmented Dark / Light picker for settings.
struct AppearanceModePicker: View {

    @EnvironmentObject private var appearance: AppearanceStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mode")
                .font(AppTheme.title(14, weight: .heavy))
                .foregroundStyle(AppTheme.ink)

            HStack(spacing: 8) {
                modeChip(title: "Dark", icon: "moon.fill", dark: true)
                modeChip(title: "Light", icon: "sun.max.fill", dark: false)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func modeChip(title: String, icon: String, dark: Bool) -> some View {
        let selected = appearance.isDark == dark
        return Button {
            ClickSoundService.shared.playClick(style: .soft)
            appearance.setDark(dark)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
                    .font(AppTheme.body(13, weight: .bold))
            }
            .foregroundStyle(selected ? Color(hex: "#121214") : AppTheme.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                selected
                    ? AnyShapeStyle(AppTheme.accentGradient)
                    : AnyShapeStyle(AppTheme.surfaceLight)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
