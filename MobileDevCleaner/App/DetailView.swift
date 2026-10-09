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
        case .category(let id):
            let info = CategoryInfo.info(for: id)
            ContentUnavailableView(info.name, systemImage: info.symbol)
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
