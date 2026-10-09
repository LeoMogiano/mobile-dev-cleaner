import SwiftUI

struct CategoryView: View {
    let category: CategoryID

    @Environment(ScanStore.self) private var scanStore
    @Environment(SelectionStore.self) private var selectionStore
    @Environment(SettingsStore.self) private var settingsStore
    @Environment(AppRouter.self) private var router
    @State private var viewModel: CategoryViewModel?

    var body: some View {
        ScrollView {
            if let viewModel {
                content(viewModel)
                    .frame(maxWidth: 860)
                    .padding(.horizontal, 24)
                    .padding(.top, 22)
                    .padding(.bottom, 90)
                    .frame(maxWidth: .infinity)
            }
        }
        .task(id: category) {
            viewModel = CategoryViewModel(
                category: category, scan: scanStore, selection: selectionStore,
                settings: settingsStore, router: router
            )
        }
    }

    private func content(_ vm: CategoryViewModel) -> some View {
        @Bindable var vm = vm
        return VStack(spacing: 14) {
            CategoryHeader(category: category, sizeText: vm.sizeText, badges: vm.badges)
            if vm.showsAccessBanner {
                AccessBanner()
            }
            MDCExplainerCard(
                whatIsIt: vm.info.whatIsIt, ifDeleted: vm.info.ifDeleted, comesBack: vm.info.comesBack,
                isExpanded: $vm.isExplainerExpanded
            )
            if vm.isEmpty {
                emptyState
            } else {
                actions(vm)
                if vm.groups.isEmpty {
                    Text("Nada coincide con el filtro o la búsqueda.")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color.mdcText3)
                        .padding(28)
                }
                ForEach(vm.groups) { group in
                    CandidateGroupView(
                        group: group,
                        onToggle: { vm.handle(.toggle($0)) },
                        onInspect: { vm.handle(.inspect($0)) },
                        onShowInFinder: { vm.handle(.showInFinder($0)) }
                    )
                }
            }
        }
    }

    private func actions(_ vm: CategoryViewModel) -> some View {
        HStack(spacing: 8) {
            Text(vm.countText)
                .font(.system(size: 12))
                .foregroundStyle(Color.mdcText2)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Marcar todo") { vm.handle(.selectAll) }
                .keyboardShortcut("a")
                .help("Marcar todo (⌘A)")
            Button("Ninguno") { vm.handle(.selectNone) }
        }
        .buttonStyle(MDCSecondaryButtonStyle(height: 24, horizontalPadding: 10, weight: .regular))
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            Image(systemName: CategoryInfo.info(for: category).symbol)
                .font(.system(size: 28))
                .foregroundStyle(Color.mdcText3)
                .frame(width: 64, height: 64)
                .background(Color.mdcFill, in: Circle())
            Text("No encontrado")
                .font(.system(size: 15, weight: .semibold))
                .padding(.top, 14)
            Text("No hay nada de esta categoría en tu Mac.")
                .font(.system(size: 12.5))
                .foregroundStyle(Color.mdcText2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
    }
}

/// Category variant of the access banner: bold title, explanation, no dismiss.
private struct AccessBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 16))
                .foregroundStyle(Color.mdcCostInk)
            (Text("Algunas carpetas no se pudieron medir. ").fontWeight(.semibold)
                + Text("Esta carpeta es del sistema y necesita Acceso total al disco.").foregroundStyle(Color.mdcText2))
                .font(.system(size: 12.5))
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Dar acceso") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(MDCSecondaryButtonStyle())
        }
        .padding(EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 12))
        .background(Color.mdcCostBg, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
