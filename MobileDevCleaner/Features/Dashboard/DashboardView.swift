import SwiftUI

struct DashboardView: View {
    var body: some View {
        ContentUnavailableView(
            "Mobile Dev Cleaner",
            systemImage: "internaldrive",
            description: Text("Recupera espacio sin romper nada.")
        )
    }
}

#Preview {
    DashboardView()
}
