//
//  MixtapeTheme.swift
//  mixtape
//
//  Created by ManoveKumar on 06/11/2026.
//


import Foundation

struct MixtapeTheme: Codable, Hashable {
    var bodyColorHex: String = "#25212F"
    var labelColorHex: String = "#8B5CF6"
    var backgroundColorHex: String = "#100B1B"
    var textColorHex: String = "#FFFFFF"

    var cassetteStyle: String = "metallic"
    var reelStyle: String = "silver"
    var coverImageURL: String?
    var isAnimated: Bool = true

    static let luxuryPurple = MixtapeTheme()

    static let midnightBlack = MixtapeTheme(
        bodyColorHex: "#171717",
        labelColorHex: "#A855F7",
        backgroundColorHex: "#080808",
        textColorHex: "#FFFFFF"
    )

    static let silverDream = MixtapeTheme(
        bodyColorHex: "#BFC3CC",
        labelColorHex: "#64748B",
        backgroundColorHex: "#111827",
        textColorHex: "#FFFFFF"
    )
}
