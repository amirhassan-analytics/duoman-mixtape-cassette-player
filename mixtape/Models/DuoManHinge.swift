//
//  DuoManHinge.swift
//  mixtape
//
//  Fold / hinge phases for DuoMan (iPhone Duo + single-phone simulation).
//

import Foundation

enum DuoManPhase: String, CaseIterable, Identifiable {
    case open
    case inserting
    case closing
    case closed

    var id: String { rawValue }

    var isBayVisible: Bool {
        self == .open || self == .inserting
    }

    var isDeckVisible: Bool {
        self == .closing || self == .closed
    }

    var statusLine: String {
        switch self {
        case .open: return "OPEN — LOAD A TAPE"
        case .inserting: return "INSERTING CASSETTE…"
        case .closing: return "HINGE CLOSING…"
        case .closed: return "PLAYING"
        }
    }
}
