import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }
            AppearanceSettingsView()
                .tabItem { Label("Apariencia", systemImage: "display") }
            AdvancedSettingsView()
                .tabItem { Label("Avanzado", systemImage: "slider.horizontal.3") }
            CreatorSettingsView()
                .tabItem { Label("Creador", systemImage: "person.crop.circle") }
            AboutSettingsView()
                .tabItem { Label("Acerca de", systemImage: "info.circle") }
        }
        .frame(width: 560)
        .frame(minHeight: 420)
    }
}
