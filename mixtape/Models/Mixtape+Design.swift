//
//  Mixtape+Design.swift
//  mixtape
//

import SwiftUI
import UIKit

extension Mixtape {
    var accentColor: Color {
        Color(hex: design.accentColorHex)
    }

    var shellTintColor: Color {
        Color(hex: design.shellTintHex)
    }

    var labelUIImage: UIImage? {
        design.drawingPNGData.flatMap(UIImage.init(data:))
    }
}
