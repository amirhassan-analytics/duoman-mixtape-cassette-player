//
//  AppearanceStore.swift
//  mixtape
//
//  Persisted dark / light appearance for the whole app.
//

import SwiftUI
import Combine

@MainActor
final class AppearanceStore: ObservableObject {

    static let shared = AppearanceStore()

    private static let key = "duoman.appearance.isDark"

    @Published var isDark: Bool {
        didSet {
            UserDefaults.standard.set(isDark, forKey: Self.key)
        }
    }

    var colorScheme: ColorScheme {
        isDark ? .dark : .light
    }

    var label: String {
        isDark ? "Dark" : "Light"
    }

    init() {
        if UserDefaults.standard.object(forKey: Self.key) == nil {
            // Default to dark (DUOMAN metallic)
            isDark = true
        } else {
            isDark = UserDefaults.standard.bool(forKey: Self.key)
        }
    }

    func toggle() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isDark.toggle()
        }
        ClickSoundService.shared.playClick(style: .soft)
    }

    func setDark(_ dark: Bool) {
        guard isDark != dark else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            isDark = dark
        }
    }
}
