import SwiftUI

struct FullDiskAccessSheet: View {
    @Environment(AppRouter.self) private var router
    @Environment(ScanStore.self) private var scanStore
    @State private var viewModel: FullDiskAccessViewModel?

    var body: some View {
        let status = viewModel?.status ?? .idle
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                FullDiskAccessIcon()
                Text("Permite el acceso total al disco")
                    .font(.system(size: 17, weight: .bold))
                    .padding(.top, 16)
                Text("Lo necesitamos para medir los runtimes de simulador y algunas carpetas de sistema. Solo leemos tamaños; nunca abrimos tus archivos ni enviamos nada fuera de tu Mac.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color.mdcText2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
                    .padding(.top, 6)
                FullDiskAccessGuide(status: status).padding(.top, 18)
            }
            .padding(.top, 26)
            .padding(.horizontal, 28)
            .padding(.bottom, 6)

            HStack(spacing: 8) {
                Spacer()
                Button("Ahora no") {
                    viewModel?.handle(.stopWaiting)
                    router.isFullDiskAccessPresented = false
                }
                .buttonStyle(MDCSecondaryButtonStyle(height: 28, horizontalPadding: 14, fontSize: 13, weight: .regular))
                .keyboardShortcut(.cancelAction)

                Button(primaryTitle(status)) { primaryAction(status) }
                    .buttonStyle(MDCPrimaryButtonStyle(horizontalPadding: 16))
                    .keyboardShortcut(.defaultAction)
                    .disabled(status == .waiting)
            }
            .padding(.top, 12)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .frame(width: 520)
        .task {
            guard viewModel == nil else { return }
            let model = FullDiskAccessViewModel(checker: sl())
            model.onGranted = { [router, scanStore] in
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(900))
                    router.isFullDiskAccessPresented = false
                    router.toast = L10n.string("Acceso total al disco concedido")
                    scanStore.handle(.start)
                }
            }
            viewModel = model
            model.handle(.refresh)
        }
    }

    private func primaryTitle(_ status: FullDiskAccessViewModel.Status) -> LocalizedStringKey {
        switch status {
        case .idle: "Abrir Ajustes del Sistema"
        case .waiting: "Esperando permiso…"
        case .granted: "Listo"
        }
    }

    private func primaryAction(_ status: FullDiskAccessViewModel.Status) {
        if status == .granted {
            router.isFullDiskAccessPresented = false
        } else {
            viewModel?.handle(.openSystemSettings)
        }
    }
}
