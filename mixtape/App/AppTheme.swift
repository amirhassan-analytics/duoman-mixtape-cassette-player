//
//  AppTheme.swift
//  mixtape
//
//  DUOMAN theme — adaptive dark metallic / light mode + gold chrome accents.
//

import SwiftUI
import UIKit

enum AppTheme {
    // MARK: Palette (adaptive)

    /// Gold chrome accent (same in both modes).
    static let accent = Color(hex: "#E8C547")
    static let accentDeep = Color(hex: "#C4A020")
    static let accentSoft = Color.adaptive(light: "#FFF6D6", dark: "#2A2618")

    static let yellow = accent
    static let yellowDeep = accentDeep
    static let yellowSoft = accentSoft

    static let sportsBlue = Color(hex: "#5B8DEF")
    static let sportsBlueDark = Color(hex: "#3A5FA8")
    static let sportsRed = Color(hex: "#E21820")

    static let chrome = Color(hex: "#D7D7D7")
    static let chromeDark = Color(hex: "#8E8E8E")

    static let ink = Color.adaptive(light: "#17181C", dark: "#FFFFFF")

    static let background = Color.adaptive(light: "#F3F1EC", dark: "#0A0A0C")
    static let surface = Color.adaptive(light: "#FFFFFF", dark: "#1A1A1E")
    static let surfaceLight = Color.adaptive(light: "#EBE7E0", dark: "#242428")
    static let surfaceWarm = Color.adaptive(light: "#F7F3EA", dark: "#1E1E22")

    static let secondaryText = Color.adaptive(light: "#6B6455", dark: "#9A9690")

    static let purple = sportsBlue
    static let violet = sportsBlueDark
    static let lavender = accentDeep
    static let recordingRed = sportsRed
    static let white = Color.white

    // MARK: Metrics

    static let cardRadius: CGFloat = 22
    static let softRadius: CGFloat = 16

    // MARK: Gradients

    static var yellowGradient: LinearGradient { accentGradient }

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#F0D56A"), accent, accentDeep],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var metallicGradient: LinearGradient {
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

    static var chromeGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white,
                chrome,
                chromeDark,
                Color.white.opacity(0.85)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var pageBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color.adaptive(light: "#FAF8F4", dark: "#141416"),
                background,
                Color.adaptive(light: "#EDE8DF", dark: "#050506")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: Fonts

    static func title(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Shared components

struct ScreenBackground: View {
    var body: some View {
        AppTheme.pageBackground
            .ignoresSafeArea()
    }
}

struct SoftPanel<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .fill(AppTheme.surface)
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 5)
            )
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            }
    }
}

struct PrimaryCTA: View {
    let title: String
    var icon: String?
    let action: () -> Void

    var body: some View {
        Button {
            ClickSoundService.shared.playClick(style: .hard)
            action()
        } label: {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .bold))
                }
                Text(title)
                    .font(AppTheme.title(15))
            }
            .foregroundStyle(Color(hex: "#121214"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.accentGradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct EmptyHint: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
            Text(title)
                .font(AppTheme.title(16))
                .foregroundStyle(AppTheme.ink)
            Text(message)
                .font(AppTheme.body(13))
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

struct FriendlySectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(AppTheme.title(18))
                .foregroundStyle(AppTheme.ink)
            if let subtitle {
                Text(subtitle)
                    .font(AppTheme.body(12))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(
            in: CharacterSet.alphanumerics.inverted
        )

        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255

        self.init(
            .sRGB,
            red: red,
            green: green,
            blue: blue,
            opacity: 1
        )
    }

    /// Light / dark adaptive color that follows `preferredColorScheme`.
    static func adaptive(light: String, dark: String) -> Color {
        Color(
            uiColor: UIColor { traits in
                let hex = traits.userInterfaceStyle == .dark ? dark : light
                return UIColor(Color(hex: hex))
            }
        )
    }
}
