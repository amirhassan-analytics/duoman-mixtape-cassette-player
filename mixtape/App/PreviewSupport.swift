//
//  PreviewSupport.swift
//  mixtape
//

import SwiftUI

enum PreviewSupport {
    @MainActor
    static func wrap<Content: View>(_ content: Content) -> some View {
        content
            .environmentObject(MixtapeStore())
            .environmentObject(PlaybackService())
            .environmentObject(AppearanceStore.shared)
            .preferredColorScheme(AppearanceStore.shared.colorScheme)
    }
}
