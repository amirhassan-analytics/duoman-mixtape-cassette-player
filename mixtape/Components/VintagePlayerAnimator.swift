//
//  VintagePlayerAnimator.swift
//  mixtape
//
//  Real-device sequence: open door (right) → slide cassette in → close door.
//

import SwiftUI

@MainActor
enum VintagePlayerAnimator {

    /// 1) Door opens to the right  2) Cassette slides in from the right  3) Door latches.
    static func insert(
        durationScale: Double = 1,
        update: @escaping (VintagePlayerPhase) -> Void,
        onComplete: @escaping () -> Void
    ) {
        let s = max(durationScale, 0.5)

        // 1) Open the door fully first — tape waits off to the right
        withAnimation(.easeOut(duration: 0.65 * s)) {
            update(.doorOpening)
        }
        ClickSoundService.shared.playClick(style: .mechanica)

        // 2) Only after the door is open, slide the cassette in from the right
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85 * s) {
            withAnimation(.spring(response: 0.9 * s, dampingFraction: 0.8)) {
                update(.inserting)
            }
            ClickSoundService.shared.playClick(style: .hard)
        }

        // 3) Seat complete — start closing the door
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.75 * s) {
            withAnimation(.easeInOut(duration: 0.7 * s)) {
                update(.doorClosing)
            }
            ClickSoundService.shared.playClick(style: .mechanica)
        }

        // 4) Latch shut
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5 * s) {
            withAnimation(.spring(response: 0.45 * s, dampingFraction: 0.9)) {
                update(.loaded)
            }
            ClickSoundService.shared.playClick(style: .hard)
            onComplete()
        }
    }

    /// Door opens right → cassette slides out right → door closes.
    static func eject(
        durationScale: Double = 1,
        update: @escaping (VintagePlayerPhase) -> Void,
        onComplete: @escaping () -> Void
    ) {
        let s = max(durationScale, 0.5)

        withAnimation(.easeOut(duration: 0.55 * s)) {
            update(.ejecting)
        }
        ClickSoundService.shared.playClick(style: .hard)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8 * s) {
            withAnimation(.spring(response: 0.75 * s, dampingFraction: 0.82)) {
                update(.ejected)
            }
            ClickSoundService.shared.playClick(style: .mechanica)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 * s) {
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
