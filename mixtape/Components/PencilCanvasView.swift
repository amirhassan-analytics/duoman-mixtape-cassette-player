//
//  PencilCanvasView.swift
//  mixtape
//

import SwiftUI
import PencilKit

struct PencilCanvasView: UIViewRepresentable {

    var drawing: PKDrawing
    var inkColor: UIColor
    var brushSize: CGFloat
    var isDrawingEnabled: Bool
    var onDrawingChanged: (PKDrawing) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onDrawingChanged: onDrawingChanged)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
        canvas.overrideUserInterfaceStyle = .light
        canvas.drawing = drawing
        canvas.tool = PKInkingTool(.marker, color: inkColor, width: brushSize)
        canvas.isUserInteractionEnabled = isDrawingEnabled
        context.coordinator.canvas = canvas
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        context.coordinator.onDrawingChanged = onDrawingChanged
        uiView.isUserInteractionEnabled = isDrawingEnabled
        uiView.tool = PKInkingTool(.marker, color: inkColor, width: brushSize)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var onDrawingChanged: (PKDrawing) -> Void
        weak var canvas: PKCanvasView?

        init(onDrawingChanged: @escaping (PKDrawing) -> Void) {
            self.onDrawingChanged = onDrawingChanged
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let drawing = canvasView.drawing
            DispatchQueue.main.async {
                self.onDrawingChanged(drawing)
            }
        }
    }
}
