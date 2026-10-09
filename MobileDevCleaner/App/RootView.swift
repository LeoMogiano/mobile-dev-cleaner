import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationSplitView {
            List {
                Label("Resumen", systemImage: "internaldrive")
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 240)
        } detail: {
            DashboardView()
        }
    }
}

#Preview {
    RootView()
}
