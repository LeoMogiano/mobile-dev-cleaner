#if DEBUG
import SwiftUI

/// `MobileDevCleaner --render-gallery <dir>`: renders design-system components to PNGs
/// (light/dark × glass/classic) so UI parity can be checked without screen capture.
enum GalleryRenderer {
    static var outputDirectory: URL? {
        let args = CommandLine.arguments
        guard let index = args.firstIndex(of: "--render-gallery"), index + 1 < args.count else { return nil }
        return URL(filePath: args[index + 1], directoryHint: .isDirectory)
    }

    @MainActor
    static func run(to directory: URL) -> Never {
        FontRegistrar.registerBundledFonts()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for scheme in [ColorScheme.light, .dark] {
            for material in MDCMaterial.allCases {
                let name = "gallery-\(scheme == .light ? "light" : "dark")-\(material.rawValue).png"
                let appearance = NSAppearance(named: scheme == .light ? .aqua : .darkAqua)
                appearance?.performAsCurrentDrawingAppearance {
                    let renderer = ImageRenderer(content: Gallery()
                        .environment(\.mdcMaterial, material)
                        .environment(\.colorScheme, scheme))
                    renderer.scale = 2
                    if let image = renderer.nsImage,
                       let tiff = image.tiffRepresentation,
                       let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
                        try? png.write(to: directory.appending(path: name))
                    }
                }
            }
        }
        exit(0)
    }
}

private struct Gallery: View {
    @State private var expanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MDCHeroNumber(bytes: 32_400_000_000, animates: false)
            MDCBreakdownBar(segments: [
                .init(id: "r", value: 18_200_000_000, color: .mdcRegen),
                .init(id: "c", value: 14_200_000_000, color: .mdcCost),
            ], height: 12, gap: 2)
            HStack(spacing: 8) {
                MDCRiskBadge(kind: .regenerates)
                MDCRiskBadge(kind: .hasCost)
                MDCRiskBadge(kind: .protected)
                MDCSizeBar(fraction: 0.6)
                MDCCheckbox(isOn: true) {}
                MDCCheckbox(isOn: false) {}
            }
            HStack(spacing: 8) {
                Button("Limpiar 18,2 GB") {}.buttonStyle(MDCPrimaryButtonStyle())
                Button("Dar acceso") {}.buttonStyle(MDCSecondaryButtonStyle())
                Toggle("Mover a la Papelera", isOn: .constant(true)).toggleStyle(MDCSwitchToggleStyle()).frame(width: 220)
            }
            MDCBanner(message: "Algunas carpetas no se pudieron medir.", actionTitle: "Dar acceso", onAction: {}, onDismiss: {})
            MDCExplainerCard(
                whatIsIt: "Archivos intermedios que Xcode genera al compilar cada proyecto.",
                ifDeleted: "El próximo build de ese proyecto tardará más: compila desde cero.",
                comesBack: "Sí. Xcode lo regenera en cuanto compilas.",
                isExpanded: $expanded
            )
            VStack(alignment: .leading, spacing: 4) {
                Text("Limpieza recomendada").font(.system(size: 15, weight: .semibold))
                Text("18,2 GB que Xcode y Gradle regeneran solos.").foregroundStyle(Color.mdcText2)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .mdcCard()
            MDCSelectionBar(count: 3, bytes: 4_200_000_000, onDeselect: {}, onReview: {})
            MDCToast(message: "Está en Carpetas excluidas (Ajustes › General)")
            MDCEmptyState(symbol: "checkmark", title: "Tu Mac está ordenada.", message: "No hay nada que limpiar ahora mismo.")
        }
        .font(.system(size: 13))
        .foregroundStyle(Color.mdcText1)
        .padding(24)
        .frame(width: 820)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
#endif
