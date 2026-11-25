//
//  VintagePlayerPhase.swift
//  mixtape
//
//  Mechanical states for the vintage cassette deck animation.
//  Sequence: door opens right → tape slides in from right → door latches.
//

import Foundation

enum VintagePlayerPhase: String, CaseIterable, Identifiable, Equatable {
    case empty
    case doorOpening
    case inserting
    case doorClosing
    case loaded
    case ejecting
    case ejected

    var id: String { rawValue }

    /// Door: 0 = shut, 1 = fully open to the right.
    var doorOpenAmount: Double {
        switch self {
        case .empty, .loaded: return 0
        case .doorOpening: return 1
        case .inserting, .ejecting: return 1
        case .doorClosing: return 0.3
        case .ejected: return 0.9
        }
    }

    /// Cassette seat: 0 = fully off to the right, 1 = locked on spindles.
    var cassetteSeatAmount: Double {
        switch self {
        case .empty: return 0
        case .doorOpening: return 0
        case .inserting: return 0.62
        case .doorClosing: return 0.95
        case .loaded: return 1
        case .ejecting: return 0.3
        case .ejected: return 0
        }
    }

    var showsCassette: Bool {
        switch self {
        case .empty: return false
        case .doorOpening, .inserting, .doorClosing, .loaded, .ejecting, .ejected: return true
        }
    }

    var statusLabel: String {
        switch self {
        case .empty: return "EMPTY"
        case .doorOpening: return "DOOR OPEN"
        case .inserting: return "INSERTING"
        case .doorClosing: return "LATCHING"
        case .loaded: return "LOADED"
        case .ejecting: return "EJECTING"
        case .ejected: return "EJECTED"
        }
    }

    static func fromDuoMan(_ phase: DuoManPhase) -> VintagePlayerPhase {
        switch phase {
        case .open: return .empty
        case .inserting: return .inserting
        case .closing: return .doorClosing
        case .closed: return .loaded
        }
    }
}

enum CassetteReelMotion: Equatable {
    case stopped
    case play
    case rewind
    case fastForward

    var isSpinning: Bool { self != .stopped }

    var degreesPerSecond: Double {
        switch self {
        case .stopped: return 0
        case .play: return 220
        case .rewind: return -520
        case .fastForward: return 460
        }
    }
}
