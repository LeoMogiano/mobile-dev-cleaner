import SwiftUI

struct DetailView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        content
            .navigationTitle(title)
    }

    @ViewBuilder
    private var content: some View {
        switch router.selection {
        case .overview:
            DashboardView()
        case .category(let id) where id.holdsDevices:
            DevicesView(category: id)
                .id(id)
        case .category(let id):
            CategoryView(category: id)
                .id(id)
        case .history:
            HistoryView()
        }
    }

    private var title: String {
        switch router.selection {
        case .overview: L10n.string("Resumen")
        case .history: L10n.string("Historial")
        case .category(let id): id.tool.displayName
        }
    }
}
