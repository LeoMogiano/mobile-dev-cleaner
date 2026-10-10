import SwiftUI

struct GeneralSettingsView: View {
    @Environment(AppRouter.self) private var router
    @Environment(ScanStore.self) private var scanStore
    @Environment(SettingsStore.self) private var settings
    @State private var viewModel: GeneralSettingsViewModel?

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section("Herramientas a escanear") {
                ToolToggle(title: "Xcode", detail: "Builds, simuladores, runtimes y cachés",
                           symbol: "hammer", tint: .mdcXcode, isOn: $settings.scanXcode)
                ToolToggle(title: "Android", detail: "Gradle, SDK, emuladores y Android Studio",
                           symbol: "android", tint: .mdcAndroid, isOn: $settings.scanAndroid)
                ToolToggle(title: "Flutter", detail: "Proyectos, caché de pub, SDK y FVM",
                           symbol: "flutter", tint: .mdcFlutter, isOn: $settings.scanFlutter)
            }
            Section {
                Toggle("Escanear al abrir la app", isOn: $settings.scanOnOpen)
                Toggle(isOn: $settings.showEmpty) {
                    Text("Mostrar categorías vacías en la barra lateral")
                    Text("Aparecen atenuadas con “No encontrado”.")
                }
            }
            Section("Notificaciones") {
                Toggle(isOn: Binding(
                    get: { settings.notifyOnFinish },
                    set: { viewModel?.handle(.setNotifyOnFinish($0)) }
                )) {
                    Text("Avisarme cuando termine la limpieza")
                    Text(viewModel?.notificationsDenied == true
                         ? L10n.string("Están desactivadas en Ajustes del Sistema › Notificaciones.")
                         : L10n.string("Una sola notificación con lo que liberaste. Nunca te avisamos para que limpies."))
                }
            }
            Section {
                ExcludedFoldersSection(
                    paths: settings.excludedPaths,
                    onAdd: { viewModel?.handle(.addExcludedFolder) },
                    onRemove: { viewModel?.handle(.removeExcludedFolder($0)) })
            } header: {
                Text("Carpetas excluidas")
            } footer: {
                Text("Nunca se marcarán, ni siquiera en la limpieza recomendada. Útil para el proyecto en el que trabajas a diario.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.mdcText2)
            }
            Section("Seguridad") {
                Toggle(isOn: $settings.moveToTrash) {
                    Text("Mover a la Papelera en vez de eliminar")
                    Text("Puedes recuperarlos desde la Papelera. El espacio se libera al vaciarla.")
                }
                Toggle(isOn: $settings.confirmCost) {
                    Text("Pedir confirmación extra para elementos con costo")
                    Text("Tendrás que marcar “Entiendo” antes de limpiar.")
                }
                Toggle(isOn: .constant(true)) {
                    Label("No limpiar si Xcode, Android Studio, Flutter o un emulador están abiertos", systemImage: "lock.fill")
                        .labelStyle(.titleAndIcon)
                    Text("Evita corromper builds en curso. Siempre activo.")
                }
                .disabled(true)
            }
            Section("Permisos") {
                LabeledContent {
                    accessStatus
                } label: {
                    Text("Acceso total al disco")
                    Text("Necesario para medir runtimes y carpetas de sistema")
                }
            }
        }
        .formStyle(.grouped)
        .task {
            let model = GeneralSettingsViewModel(
                settings: settings, fullDiskAccess: sl(), notifications: sl(), router: router,
                chooseFolder: Self.chooseFolder)
            viewModel = model
            model.handle(.appear)
        }
        .onChange(of: settings.enabledTools) { scanStore.handle(.start) }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            viewModel?.handle(.appear)
        }
    }

    @ViewBuilder
    private var accessStatus: some View {
        if viewModel?.hasFullDiskAccess == true {
            Label("Concedido", systemImage: "checkmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.mdcRegenInk)
        } else {
            HStack(spacing: 8) {
                Text("No concedido")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.mdcCostInk)
                Button("Dar acceso") { viewModel?.handle(.grantFullDiskAccess) }
            }
        }
    }

    @MainActor
    private static func chooseFolder() async -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = L10n.string("Excluir")
        return await panel.begin() == .OK ? panel.url : nil
    }
}

private struct ToolToggle: View {
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    let symbol: String
    let tint: Color
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            ToolLabel(title: title, detail: detail, symbol: symbol, tint: tint)
        }
    }
}

private struct ToolLabel: View {
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            MDCSymbol(name: symbol, size: 13)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(tint, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.mdcText2)
            }
        }
    }
}
