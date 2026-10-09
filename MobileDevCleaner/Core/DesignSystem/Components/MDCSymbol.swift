import SwiftUI

/// SF Symbol by name, or a bundled template asset for marks SF Symbols lacks (Android).
struct MDCSymbol: View {
    let name: String
    let size: CGFloat

    private static let assets: Set<String> = ["android"]

    var body: some View {
        if Self.assets.contains(name) {
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: size * 1.15, height: size * 1.15)
        } else {
            Image(systemName: name).font(.system(size: size))
        }
    }
}
