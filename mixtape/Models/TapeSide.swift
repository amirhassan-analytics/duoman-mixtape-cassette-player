//
//  TapeSide.swift
//  mixtape
//
//  Classic magnetic cassette: Side A + Side B, 30 minutes each.
//

import Foundation

enum TapeSide: String, Codable, CaseIterable, Identifiable, Hashable {
    case a
    case b

    var id: String { rawValue }

    var label: String {
        switch self {
        case .a: return "Side A"
        case .b: return "Side B"
        }
    }

    var shortLabel: String {
        switch self {
        case .a: return "A"
        case .b: return "B"
        }
    }

    /// Classic C60 tape ≈ 30 minutes per side.
    static let capacitySeconds: TimeInterval = 30 * 60

    var opposite: TapeSide {
        self == .a ? .b : .a
    }
}

enum TapeCapacity {
    static let sideMinutes = 30
    static let sideSeconds: TimeInterval = TimeInterval(sideMinutes * 60)

    static func format(_ seconds: TimeInterval) -> String {
        let total = max(Int(seconds.rounded()), 0)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    static func usedFraction(_ used: TimeInterval) -> Double {
        min(max(used / sideSeconds, 0), 1)
    }
}
