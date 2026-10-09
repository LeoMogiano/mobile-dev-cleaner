import SwiftUI
import UniformTypeIdentifiers

struct AdvancedSettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(ScanStore.self) private var scan
    @Environment(SelectionStore.self) private var selection
    @Environment(AppRouter.self) private var router
    @State private var viewModel: AdvancedSettingsViewModel?

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section {
                Toggle(isOn: $settings.showTechnicalNames) {
                    Text("Mostrar nombres técnicos y rutas completas")
                    Text("“DerivedData” en vez de “Builds de Xcode”.")
                }
                Toggle(isOn: $settings.showCommands) {
                    Text("Mostrar comandos que se ejecutarán")
                    Text("xcrun simctl erase <UDID> · avdmanager delete avd").font(.mdcMono(11))
                }
            }
            Section {
                LabeledContent {
                    Button("Vaciar caché de tamaños") { viewModel?.handle(.clearSizeCache) }
                } label: {
                    Text("Caché de tamaños ") + Text("· \(viewModel?.sizeCacheText ?? "")").foregroundStyle(Color.mdcText3)
                    Text("Hace que los re-escaneos sean casi instantáneos.")
                }
                LabeledContent {
                    HStack(spacing: 6) {
                        Button("Importar", systemImage: "square.and.arrow.down") { viewModel?.handle(.importPlan) }
                        Button("Exportar", systemImage: "square.and.arrow.up") { viewModel?.handle(.exportPlan) }
                    }
                } label: {
                    Text("Plan de limpieza")
                    Text("JSON compatible con el CLI ") + Text("mdc").font(.mdcMono(11))
                }
            }
            Section {
                LabeledContent("Mostrar el onboarding de nuevo") {
                    Button("Mostrar") { viewModel?.handle(.showOnboarding) }
                }
                LabeledContent {
                    resetControls
                } label: {
                    Text("Restablecer todos los ajustes")
                    Text("No borra nada de tu disco.")
                }
            }
        }
        .formStyle(.grouped)
        .task {
            let model = AdvancedSettingsViewModel(
                settings: settings, sizes: sl(), exportPlan: sl(), importPlan: sl(),
                scan: scan, selection: selection, router: router, files: .live)
            viewModel = model
            model.handle(.appear)
        }
    }

    @ViewBuilder
    private var resetControls: some View {
        if viewModel?.isAskingReset == true {
            HStack(spacing: 6) {
                Text("¿Seguro?").foregroundStyle(Color.mdcText2)
                Button("Cancelar") { viewModel?.handle(.cancelReset) }
                Button("Restablecer", role: .destructive) { viewModel?.handle(.confirmReset) }
                    .buttonStyle(.borderedProminent)
                    .tint(.mdcDestructive)
            }
        } else {
            Button("Restablecer…") { viewModel?.handle(.askReset) }
                .foregroundStyle(Color.mdcDestructive)
        }
    }
}

extension PlanFilePicking {
    static let live = PlanFilePicking(
        save: { data in
            let panel = NSSavePanel()
            panel.nameFieldStringValue = "mdc-plan.json"
            panel.allowedContentTypes = [.json]
            guard await panel.begin() == .OK, let url = panel.url else { return false }
            return (try? data.write(to: url, options: .atomic)) != nil
        },
        open: {
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.json]
            panel.allowsMultipleSelection = false
            guard await panel.begin() == .OK, let url = panel.url else { return nil }
            return try? Data(contentsOf: url)
        }
    )
}
