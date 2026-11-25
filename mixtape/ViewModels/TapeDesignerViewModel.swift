//
//  TapeDesignerViewModel.swift
//  mixtape
//

import Foundation
import SwiftUI
import Combine
import PencilKit
import UIKit

enum CreateTapeSegment: String, CaseIterable, Identifiable {
    case design = "Design"
    case music = "Music"
    case options = "Options"

    var id: String { rawValue }
}

@MainActor
final class TapeDesignerViewModel: ObservableObject {

    @Published var segment: CreateTapeSegment = .design
    @Published var tool: DesignTool = .draw

    @Published var title: String = "Summer Vibes"
    @Published var subtitle: String = "Tape Club"
    @Published var visibility: MixtapeVisibility = .private
    @Published var descriptionText: String = "A cassette made for warm days."

    @Published var selectedColorHex: String = "#17181C"
    @Published var brushSize: CGFloat = 8
    @Published var drawing = PKDrawing()
    @Published var labelImage: UIImage?
    @Published var stickers: [TapeSticker] = []
    @Published var texts: [TapeTextOverlay] = []
    @Published var draftText: String = ""
    @Published var songs: [Song] = []
    @Published var voiceMessages: [VoiceMessage] = []
    @Published var selectedSide: TapeSide = .a
    @Published var capacityWarning: String?
    @Published var isPreviewPlaying = false
    @Published var shellTintHex: String = "#2A2A2E"
    @Published var canvasResetID = UUID()

    private var undoStack: [PKDrawing] = []
    private var redoStack: [PKDrawing] = []
    private var labelRefreshTask: Task<Void, Never>?

    let paletteHex: [String] = [
        "#17181C",
        "#E8C547",
        "#5B8DEF",
        "#E21820",
        "#0F766E",
        "#FFFFFF",
        "#C4A020",
        "#9A9690"
    ]

    let stickerChoices = ["☀️", "🌴", "🌊", "⭐️", "❤️", "🔥", "🎵", "😎", "🌸", "🦋"]

    var selectedColor: Color { Color(hex: selectedColorHex) }
    var shellTint: Color { Color(hex: shellTintHex) }
    var accent: Color { selectedColor }
    var selectedUIColor: UIColor { UIColor(selectedColor) }

    var draftMixtapePreview: Mixtape {
        Mixtape(title: title, description: descriptionText, songs: songs, voiceMessages: voiceMessages)
    }

    var playlistSummary: String {
        let a = songs.filter { $0.side == .a }.count
        let b = songs.filter { $0.side == .b }.count
        let voices = voiceMessages.count
        return "Side A \(a) · Side B \(b) · \(voices) voice · \(draftMixtapePreview.sideSummary)"
    }

    init() {
        songs = []
        voiceMessages = []
        refreshLabelImage()
    }

    @discardableResult
    func addSong(_ song: Song) -> Bool {
        var copy = song
        copy.side = selectedSide
        let duration = copy.playDuration
        if !draftMixtapePreview.canFit(duration, on: selectedSide) {
            capacityWarning = "\(selectedSide.label) is full (30 min). Switch to \(selectedSide.opposite.label)."
            return false
        }
        capacityWarning = nil
        songs.append(copy)
        return true
    }

    @discardableResult
    func addVoice(_ message: VoiceMessage) -> Bool {
        var copy = message
        copy.side = selectedSide
        if !draftMixtapePreview.canFit(copy.durationSeconds, on: selectedSide) {
            capacityWarning = "\(selectedSide.label) is full (30 min). Switch to \(selectedSide.opposite.label)."
            return false
        }
        capacityWarning = nil
        voiceMessages.append(copy)
        return true
    }

    func removeVoice(_ id: UUID) {
        voiceMessages.removeAll { $0.id == id }
    }

    func songsOnSelectedSide() -> [Song] {
        songs.filter { $0.side == selectedSide }
    }

    func voicesOnSelectedSide() -> [VoiceMessage] {
        voiceMessages.filter { $0.side == selectedSide }
    }

    func drawingDidChange(_ drawing: PKDrawing) {
        undoStack.append(self.drawing)
        if undoStack.count > 30 {
            undoStack.removeFirst()
        }
        redoStack.removeAll()
        self.drawing = drawing
        scheduleLabelRefresh()
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(drawing)
        drawing = previous
        canvasResetID = UUID()
        refreshLabelImage()
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(drawing)
        drawing = next
        canvasResetID = UUID()
        refreshLabelImage()
    }

    func clearDrawing() {
        undoStack.append(drawing)
        drawing = PKDrawing()
        canvasResetID = UUID()
        refreshLabelImage()
    }

    func addSticker(_ emoji: String) {
        stickers.append(
            TapeSticker(
                emoji: emoji,
                x: Double.random(in: 0.18...0.72),
                y: Double.random(in: 0.25...0.72),
                scale: Double.random(in: 0.9...1.25)
            )
        )
        refreshLabelImage()
    }

    func addTextOverlay() {
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        texts.append(
            TapeTextOverlay(
                text: trimmed,
                x: 0.5,
                y: 0.2,
                colorHex: selectedColorHex,
                fontSize: 26
            )
        )
        draftText = ""
        refreshLabelImage()
    }

    private func scheduleLabelRefresh() {
        labelRefreshTask?.cancel()
        labelRefreshTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 80_000_000)
            guard !Task.isCancelled else { return }
            refreshLabelImage()
        }
    }

    func refreshLabelImage() {
        let size = CGSize(width: 600, height: 360)
        let currentDrawing = drawing
        let currentStickers = stickers
        let currentTexts = texts
        let currentTitle = title
        let inkHex = selectedColorHex == "#FFFFFF" ? "#17181C" : selectedColorHex

        let renderer = UIGraphicsImageRenderer(size: size)
        labelImage = renderer.image { _ in
            // Cream label paper on metallic tape
            UIColor(Color(hex: "#F4EFE6")).setFill()
            UIRectFill(CGRect(origin: .zero, size: size))

            UIColor(Color(hex: "#2A2A2E")).setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: size.width, height: 54))

            if !currentDrawing.strokes.isEmpty {
                let ink = currentDrawing.image(from: CGRect(origin: .zero, size: size), scale: 2)
                ink.draw(in: CGRect(origin: .zero, size: size))
            }

            for sticker in currentStickers {
                let font = UIFont.systemFont(ofSize: CGFloat(38 * sticker.scale))
                let attr: [NSAttributedString.Key: Any] = [.font: font]
                let point = CGPoint(x: sticker.x * size.width, y: sticker.y * size.height)
                (sticker.emoji as NSString).draw(at: point, withAttributes: attr)
            }

            for item in currentTexts {
                let font = UIFont.systemFont(ofSize: CGFloat(max(item.fontSize, 22)), weight: .heavy)
                let raw = item.colorHex.uppercased()
                let safeHex = (raw == "#FFFFFF" || raw == "#E8C547" || raw == "#C4A020" || raw == "#F4EFE6")
                    ? "#17181C"
                    : item.colorHex
                let attr: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor(Color(hex: safeHex))
                ]
                let text = item.text as NSString
                let textSize = text.size(withAttributes: attr)
                let origin = CGPoint(
                    x: item.x * size.width - textSize.width / 2,
                    y: item.y * size.height - textSize.height / 2
                )
                text.draw(at: origin, withAttributes: attr)
            }

            if currentTexts.isEmpty {
                let font = UIFont.systemFont(ofSize: 36, weight: .black)
                let attr: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor(Color(hex: inkHex == "#E8C547" || inkHex == "#C4A020" ? "#E8C547" : (inkHex == "#17181C" ? "#FFFFFF" : inkHex)))
                ]
                let text = currentTitle as NSString
                let textSize = text.size(withAttributes: attr)
                text.draw(
                    at: CGPoint(x: (size.width - textSize.width) / 2, y: 12),
                    withAttributes: attr
                )

                let subFont = UIFont.systemFont(ofSize: 14, weight: .bold)
                let subAttr: [NSAttributedString.Key: Any] = [
                    .font: subFont,
                    .foregroundColor: UIColor(Color(hex: "#E8C547"))
                ]
                let sub = "PRIVATE MIX TAPE" as NSString
                let subSize = sub.size(withAttributes: subAttr)
                sub.draw(
                    at: CGPoint(x: (size.width - subSize.width) / 2, y: 52),
                    withAttributes: subAttr
                )
            }
        }
    }

    func buildMixtape(creatorID: UUID?) -> Mixtape {
        let design = TapeDesign(
            labelTitle: title,
            accentColorHex: "#E8C547",
            shellTintHex: shellTintHex.isEmpty ? "#2A2A2E" : shellTintHex,
            drawingPNGData: labelImage?.pngData(),
            stickers: stickers,
            texts: texts
        )

        let theme = MixtapeTheme(
            bodyColorHex: "#2A2A2E",
            labelColorHex: "#E8C547",
            backgroundColorHex: "#0A0A0C",
            textColorHex: "#FFFFFF",
            cassetteStyle: "duo-black",
            reelStyle: "silver",
            isAnimated: true
        )

        return Mixtape(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Tape" : title,
            description: descriptionText,
            creatorID: creatorID,
            songs: songs,
            voiceMessages: voiceMessages,
            theme: theme,
            visibility: visibility,
            design: design
        )
    }
}
