import SwiftUI

struct MDCToast: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 12, weight: .regular))
            .foregroundColor(.white)
            .padding(EdgeInsets(top: 7, leading: 14, bottom: 7, trailing: 14))
            .background(Color(nsColor: NSColor(srgbRed: 30/255, green: 30/255, blue: 34/255, alpha: 0.86)))
            .cornerRadius(999, antialiased: true)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func mdcToast(_ message: Binding<String?>) -> some View {
        modifier(MDCToastModifier(message: message))
    }
}

private struct MDCToastModifier: ViewModifier {
    @Binding var message: String?
    @State private var toastTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let msg = message, !msg.isEmpty {
                MDCToast(message: msg)
                    .padding(.bottom, 16)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task(id: message) {
            toastTask?.cancel()

            guard let msg = message, !msg.isEmpty else {
                return
            }

            toastTask = Task {
                try? await Task.sleep(nanoseconds: 2_200_000_000)
                if !Task.isCancelled {
                    withAnimation(reduceMotion ? nil : .default) {
                        message = nil
                    }
                }
            }
        }
    }
}
