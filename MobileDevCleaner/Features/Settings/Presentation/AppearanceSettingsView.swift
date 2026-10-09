import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @AppStorage(MDCMaterial.storageKey) private var material: MDCMaterial = .liquidGlass
    @AppStorage(AppLanguage.storageKey) private var languageKey: String = AppLanguage.system.rawValue

    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    themeButton(title: "Claro", theme: .light)
                    themeButton(title: "Oscuro", theme: .dark)
                    themeButton(title: "Automático", theme: .auto)
                }
                .frame(height: 86)
                .padding(.vertical, 8)

                Divider()

                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Material")
                        Text("Liquid Glass usa vidrio translúcido de macOS Tahoe. Clásico es el estilo de Sonoma y Sequoia.")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.mdcText2)
                    }
                    Spacer()
                    Picker("Material", selection: $material) {
                        Text("Liquid Glass (Tahoe)").tag(MDCMaterial.liquidGlass)
                        Text("Clásico").tag(MDCMaterial.classic)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Divider()

                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.mdcText2)
                    Text("Idioma")
                    Spacer()
                    Picker("Idioma", selection: Binding(
                        get: { AppLanguage(rawValue: languageKey) ?? .system },
                        set: { languageKey = $0.rawValue }
                    )) {
                        ForEach(AppLanguage.allCases, id: \.self) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Text("Algunos textos se actualizan al reiniciar la app.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.mdcText2)
            } header: {
                Text("Apariencia")
            }
        }
        .formStyle(.grouped)
    }

    private func themeButton(title: LocalizedStringKey, theme: AppTheme) -> some View {
        let isSelected = settings.theme == theme
        return VStack(spacing: 6) {
            ThemeThumbnail(theme: theme)
                .padding(2)
                .frame(width: 86, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(isSelected ? Color.mdcAccent : .clear, lineWidth: 2.5))
            Text(title)
                .font(.system(size: 11.5, weight: isSelected ? .semibold : .regular))
        }
        .contentShape(Rectangle())
        .onTapGesture { settings.theme = theme }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction { settings.theme = theme }
    }
}

/// Miniature window from the prototype: wallpaper gradient, window and sidebar.
private struct ThemeThumbnail: View {
    let theme: AppTheme

    var body: some View {
        ZStack(alignment: .bottom) {
            wallpaper
            HStack(spacing: 0) {
                Rectangle().fill(rgb(0xECECF0, dark: 0x3A3A3C)).frame(width: 17)
                Rectangle().fill(rgb(0xFFFFFF, dark: 0x2C2C2E))
            }
            .frame(width: 57, height: 36)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 4, topTrailingRadius: 4))
        }
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    @ViewBuilder
    private var wallpaper: some View {
        switch theme {
        case .light: LinearGradient(colors: [Color(hex: 0xBCD4FF), Color(hex: 0xF5D6EA)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .dark: LinearGradient(colors: [Color(hex: 0x1E2A52), Color(hex: 0x52264A)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .auto: HStack(spacing: 0) { Color(hex: 0xBCD4FF); Color(hex: 0x1E2A52) }
        }
    }

    /// Automático shows the light half on the left and the dark half on the right.
    private func rgb(_ light: UInt32, dark: UInt32) -> AnyShapeStyle {
        switch theme {
        case .light: AnyShapeStyle(Color(hex: light))
        case .dark: AnyShapeStyle(Color(hex: dark))
        case .auto: AnyShapeStyle(LinearGradient(stops: [
            .init(color: Color(hex: light), location: 0.5), .init(color: Color(hex: dark), location: 0.5),
        ], startPoint: .leading, endPoint: .trailing))
        }
    }
}
