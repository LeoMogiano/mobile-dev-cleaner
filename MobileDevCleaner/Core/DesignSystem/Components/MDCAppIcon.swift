import AppKit
import SwiftUI

struct MDCAppIcon: View {
    let size: CGFloat

    // The system icon canvas pads the tile (824 of 1024 pt); scale so the visible tile equals `size`.
    private static let tileRatio: CGFloat = 824.0 / 1024.0

    var body: some View {
        Image(nsImage: NSApp.applicationIconImage)
            .resizable()
            .interpolation(.high)
            .frame(width: size / Self.tileRatio, height: size / Self.tileRatio)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
