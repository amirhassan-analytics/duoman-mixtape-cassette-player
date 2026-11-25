//
//  PhoneMusicPicker.swift
//  mixtape
//
//  Pick songs from the iPhone Music library (not Mac Files).
//

import SwiftUI
import MediaPlayer
import AVFoundation

struct PhoneMusicPicker: UIViewControllerRepresentable {
    var onPicked: (Song) -> Void
    var onCancel: (() -> Void)? = nil
    var onError: ((String) -> Void)? = nil

    func makeUIViewController(context: Context) -> MPMediaPickerController {
        let picker = MPMediaPickerController(mediaTypes: .music)
        picker.delegate = context.coordinator
        picker.allowsPickingMultipleItems = false
        picker.showsCloudItems = true
        picker.prompt = "Choose a song from your iPhone"
        return picker
    }

    func updateUIViewController(_ uiViewController: MPMediaPickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, MPMediaPickerControllerDelegate {
        let parent: PhoneMusicPicker

        init(parent: PhoneMusicPicker) {
            self.parent = parent
        }

        func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
            guard let item = mediaItemCollection.items.first else {
                mediaPicker.dismiss(animated: true)
                parent.onCancel?()
                return
            }

            let title = item.title ?? "Unknown Song"
            let artist = item.artist ?? "Unknown Artist"
            let duration = Int(item.playbackDuration.rounded())

            // Local / downloadable file URL (DRM Apple Music streams may have none).
            guard let assetURL = item.assetURL else {
                mediaPicker.dismiss(animated: true)
                parent.onError?(
                    "This track can’t be copied (Apple Music DRM). Pick a song downloaded On My iPhone, or use Voice to record."
                )
                return
            }

            do {
                let path = try AudioLibrary.importFile(
                    from: assetURL,
                    preferredName: "\(artist)-\(title)"
                )
                let song = Song(
                    title: title,
                    artist: artist,
                    album: item.albumTitle,
                    artworkURL: nil,
                    externalID: item.playbackStoreID.isEmpty ? nil : item.playbackStoreID,
                    externalURL: path,
                    source: .personalRecording,
                    durationSeconds: max(duration, 1)
                )
                mediaPicker.dismiss(animated: true)
                parent.onPicked(song)
            } catch {
                mediaPicker.dismiss(animated: true)
                parent.onError?(error.localizedDescription)
            }
        }

        func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
            mediaPicker.dismiss(animated: true)
            parent.onCancel?()
        }
    }
}
