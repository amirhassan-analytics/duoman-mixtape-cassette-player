//
//  TapeDesign.swift
//  mixtape
//

import Foundation
import SwiftUI

enum DesignTool: String, CaseIterable, Identifiable {
    case draw
    case stickers
    case text
    case color

    var id: String { rawValue }

    var title: String {
        switch self {
        case .draw: return "Draw"
        case .stickers: return "Stickers"
        case .text: return "Text"
        case .color: return "Color"
        }
    }

    var icon: String {
        switch self {
        case .draw: return "scribble"
        case .stickers: return "face.smiling"
        case .text: return "textformat"
        case .color: return "drop.fill"
        }
    }
}

struct TapeSticker: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var emoji: String
    var x: Double
    var y: Double
    var scale: Double = 1
}

struct TapeTextOverlay: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var text: String
    var x: Double
    var y: Double
    var colorHex: String
    var fontSize: Double = 22
}

struct TapeDesign: Codable, Hashable {
    var labelTitle: String = "Summer Vibes"
    var accentColorHex: String = "#E8C547"
    var shellTintHex: String = "#2A2A2E"
    var drawingPNGData: Data?
    var stickers: [TapeSticker] = []
    var texts: [TapeTextOverlay] = []
}
