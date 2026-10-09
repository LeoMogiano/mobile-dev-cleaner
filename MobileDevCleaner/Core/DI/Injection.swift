import Foundation

/// Registration order: Core → features. Inside each module: data sources →
/// repositories → use cases → ViewModels.
@MainActor
enum Injection {
    static func setup() {
        CoreModule.register()
        ScanModule.register()
    }

    static func reset() {
        sl.reset()
    }
}
