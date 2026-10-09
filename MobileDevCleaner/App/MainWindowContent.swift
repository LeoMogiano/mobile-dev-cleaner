import SwiftUI

/// The main window is the onboarding until it's done (740×560, no toolbar), then the app.
struct MainWindowContent: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        Group {
            if router.isOnboardingPresented {
                OnboardingView()
            } else {
                RootView()
                    .frame(minWidth: 900, minHeight: 600)
            }
        }
        .background(WindowChrome(isOnboarding: router.isOnboardingPresented))
    }
}

/// Reshapes the hosting NSWindow; SwiftUI can't resize or restyle a window per content on macOS 14.
private struct WindowChrome: NSViewRepresentable {
    let isOnboarding: Bool

    final class Coordinator {
        /// Window style before the onboarding took over, restored afterwards.
        var saved: (mask: NSWindow.StyleMask, transparent: Bool, title: NSWindow.TitleVisibility)?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView { NSView() }

    func updateNSView(_ view: NSView, context: Context) {
        let isOnboarding = isOnboarding
        let coordinator = context.coordinator
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            if isOnboarding, coordinator.saved == nil {
                coordinator.saved = (window.styleMask, window.titlebarAppearsTransparent, window.titleVisibility)
                window.styleMask.remove(.resizable)
                window.styleMask.insert(.fullSizeContentView)
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.setContentSize(NSSize(width: 740, height: 560))
                window.center()
            } else if !isOnboarding, let saved = coordinator.saved {
                coordinator.saved = nil
                window.styleMask = saved.mask
                window.titlebarAppearsTransparent = saved.transparent
                window.titleVisibility = saved.title
                window.setContentSize(NSSize(width: 1100, height: 720))
                window.center()
            }
        }
    }
}
