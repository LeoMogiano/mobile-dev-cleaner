#if DEBUG
import SwiftUI

/// Onboarding steps and the Full Disk Access guide, at onboarding size.
struct OnboardingGallery: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                page { WelcomeStep() }
                page { HowItWorksStep() }
            }
            HStack(spacing: 16) {
                page {
                    VStack(spacing: 0) {
                        FullDiskAccessIcon()
                        Text("Permite el acceso total al disco")
                            .font(.mont(26, weight: .bold))
                            .padding(.top, 20)
                        FullDiskAccessGuide(status: .waiting).padding(.top, 18)
                    }
                }
                page { NotificationsStep(isAllowed: true) }
            }
            HStack(spacing: 16) {
                page { DoneStep() }
                page { FullDiskAccessGuide(status: .granted) }
            }
        }
        .font(.system(size: 13))
        .foregroundStyle(Color.mdcText1)
        .padding(24)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func page<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 56)
            .frame(width: 740, height: 452)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
#endif
