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
            ContentUnavailableView("Historial", systemImage: "clock.arrow.circlepath")
        }
    }

    private var title: String {
        switch router.selection {
        case .overview: "Resumen"
        case .history: "Historial"
        case .category(let id): id.tool == .xcode ? "Xcode" : "Android"
        }
    }
}
