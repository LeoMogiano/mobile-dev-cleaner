import SwiftUI

struct OnboardingView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(AppRouter.self) private var router
    @Environment(ScanStore.self) private var scanStore
    @State private var viewModel: OnboardingViewModel?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if let viewModel {
                    content(viewModel).id(viewModel.step)
                        .transition(.opacity)
                } else {
                    Color.clear
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 56)
            // The traffic lights sit in this strip (HTML: 40 px title bar).
            .padding(.top, 40)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel?.step)
            if let viewModel { footer(viewModel) }
        }
        .frame(width: 740, height: 560)
        .ignoresSafeArea()
        .background(OnboardingBackground())
        .task {
            guard viewModel == nil else { return }
            let model = OnboardingViewModel(
                fullDiskAccess: FullDiskAccessViewModel(checker: sl()),
                notifications: sl(),
                settings: settings,
                onFinish: { [router, scanStore] in
                    router.isOnboardingPresented = false
                    scanStore.handle(.start)
                })
            viewModel = model
            model.handle(.appear)
        }
    }

    @ViewBuilder private func content(_ model: OnboardingViewModel) -> some View {
        switch model.step {
        case .welcome: WelcomeStep()
        case .howItWorks: HowItWorksStep()
        case .fullDiskAccess:
            VStack(spacing: 0) {
                FullDiskAccessIcon()
                Text("Permite el acceso total al disco")
                    .font(.mont(26, weight: .bold))
                    .tracking(-0.78)
                    .padding(.top, 20)
                Text("Lo necesitamos para medir los runtimes de simulador y algunas carpetas de sistema. Solo leemos tamaños; nunca abrimos tus archivos ni enviamos nada fuera de tu Mac.")
                    .font(.system(size: 13.5))
                    .foregroundStyle(Color.mdcText2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 480)
                    .padding(.top, 10)
                FullDiskAccessGuide(status: model.fullDiskAccess.status).padding(.top, 18)
            }
        case .notifications: NotificationsStep(isAllowed: model.notificationsAllowed)
        case .done: DoneStep()
        }
    }

    private func footer(_ model: OnboardingViewModel) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(OnboardingViewModel.Step.allCases, id: \.rawValue) { step in
                    Capsule()
                        .fill(step == model.step ? Color.mdcAccent : Color.mdcLine2)
                        .frame(width: step == model.step ? 18 : 7, height: 7)
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: model.step)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(L10n.string("Paso \(model.step.rawValue + 1) de \(OnboardingViewModel.Step.allCases.count)"))
            .frame(maxWidth: .infinity, alignment: .leading)

            if model.showsBack {
                Button { model.handle(.back) } label: {
                    Text("Atrás").font(.system(size: 13)).foregroundStyle(Color.mdcText2)
                        .padding(.horizontal, 12).frame(height: 30)
                }
                .buttonStyle(.plain)
            }
            if let title = model.secondaryTitle {
                Button(title) { model.handle(.skip) }
                    .buttonStyle(MDCSecondaryButtonStyle(height: 30, horizontalPadding: 16, fontSize: 13, weight: .regular))
            }
            Button(model.primaryTitle) { model.handle(.next) }
                .buttonStyle(MDCPrimaryButtonStyle(height: 30, horizontalPadding: 20))
                .keyboardShortcut(.defaultAction)
                .disabled(!model.isPrimaryEnabled)
        }
        .padding(.horizontal, 24)
        .frame(height: 68)
    }
}

/// Liquid Glass: the window blurs the desktop behind it like the HTML sheet; Clásico stays solid.
private struct OnboardingBackground: View {
    @Environment(\.mdcMaterial) private var material

    var body: some View {
        if material.usesGlass {
            BehindWindowBlur().ignoresSafeArea()
        } else {
            Color(nsColor: .windowBackgroundColor).ignoresSafeArea()
        }
    }
}

private struct BehindWindowBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .underWindowBackground
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}

