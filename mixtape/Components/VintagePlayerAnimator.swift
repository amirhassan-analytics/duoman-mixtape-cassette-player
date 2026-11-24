//
//  VintagePlayerAnimator.swift
//  mixtape
//
//  Timed insert / eject sequences — door open → slide tape → latch.
//

import SwiftUI

@MainActor
enum VintagePlayerAnimator {

    /// Door opens → cassette drops onto spindles → door latches shut.
    static func insert(
        durationScale: Double = 1,
        update: @escaping (VintagePlayerPhase) -> Void,
        onComplete: @escaping () -> Void
    ) {
        let s = max(durationScale, 0.5)

        // 1) Door swings fully open
        withAnimation(.easeOut(duration: 0.55 * s)) {
            update(.doorOpening)
        }
        ClickSoundService.shared.playClick(style: .mechanica)

        // 2) Cassette slides down into the bay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65 * s) {
            withAnimation(.spring(response: 0.85 * s, dampingFraction: 0.78)) {
                update(.inserting)
            }
            ClickSoundService.shared.playClick(style: .hard)
        }

        // 3) Door starts closing over the seated tape
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.45 * s) {
            withAnimation(.easeInOut(duration: 0.75 * s)) {
                update(.doorClosing)
            }
            ClickSoundService.shared.playClick(style: .mechanica)
        }

        // 4) Latch closed
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.25 * s) {
            withAnimation(.spring(response: 0.45 * s, dampingFraction: 0.9)) {
                update(.loaded)
            }
            ClickSoundService.shared.playClick(style: .hard)
            onComplete()
        }
    }

    /// Door opens → cassette lifts out → door closes empty.
    static func eject(
        durationScale: Double = 1,
        update: @escaping (VintagePlayerPhase) -> Void,
        onComplete: @escaping () -> Void
    ) {
        let s = max(durationScale, 0.5)

        withAnimation(.easeOut(duration: 0.5 * s)) {
            update(.ejecting)
        }
        ClickSoundService.shared.playClick(style: .hard)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75 * s) {
            withAnimation(.spring(response: 0.7 * s, dampingFraction: 0.82)) {
                update(.ejected)
            }
            ClickSoundService.shared.playClick(style: .mechanica)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4 * s) {
            withAnimation(.easeInOut(duration: 0.55 * s)) {
                update(.empty)
            }
            ClickSoundService.shared.playClick(style: .soft)
            onComplete()
        }
    }

    static func flashReel(
        motion: CassetteReelMotion,
        seconds: Double = 0.55,
        setMotion: @escaping (CassetteReelMotion?) -> Void,
        then action: @escaping () -> Void
    ) {
        setMotion(motion)
        ClickSoundService.shared.playClick(style: .mechanica)
        action()
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            setMotion(nil)
        }
    }
}
