//
//  AudioRouteService.swift
//  mixtape
//

import Foundation
import AVFoundation
import Combine

@MainActor
final class AudioRouteService: ObservableObject {

    @Published private(set) var connectionText = "Playing on iPhone"
    @Published private(set) var isExternalOutput = false

    private var routeObserver: NSObjectProtocol?

    init() {
        updateRoute()

        routeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateRoute()
            }
        }
    }

    func updateRoute() {
        Task { [weak self] in
            let outputs = await AudioSessionCoordinator.currentOutputs()
            await MainActor.run {
                self?.apply(outputs: outputs)
            }
        }
    }

    private func apply(outputs: [AVAudioSessionPortDescription]) {
        if outputs.contains(where: {
            $0.portType == .bluetoothA2DP ||
            $0.portType == .bluetoothHFP ||
            $0.portType == .bluetoothLE
        }) {
            connectionText = "Bluetooth connected"
            isExternalOutput = true
        } else if outputs.contains(where: {
            $0.portType == .headphones
        }) {
            connectionText = "Wired headphones connected"
            isExternalOutput = true
        } else if outputs.contains(where: {
            $0.portType == .airPlay
        }) {
            connectionText = "AirPlay connected"
            isExternalOutput = true
        } else {
            connectionText = "Playing on iPhone"
            isExternalOutput = false
        }
    }

    deinit {
        if let routeObserver {
            NotificationCenter.default.removeObserver(routeObserver)
        }
    }
}
