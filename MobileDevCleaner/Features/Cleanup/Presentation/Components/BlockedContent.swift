import SwiftUI

struct BlockedContent: View {
    let apps: [BlockingAppRow]
    let isRechecking: Bool
    let onCancel: () -> Void
    let onRecheck: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            list
                .padding(EdgeInsets(top: 14, leading: 26, bottom: 4, trailing: 26))
            HStack(spacing: 8) {
                Spacer()
                Button("Cancelar", action: onCancel)
                    .buttonStyle(MDCSecondaryButtonStyle(height: 28, horizontalPadding: 14, fontSize: 13, weight: .regular))
                    .keyboardShortcut(.cancelAction)
                Button(action: onRecheck) {
                    if isRechecking {
                        HStack(spacing: 7) {
                            ProgressView().controlSize(.mini).tint(.white)
                            Text("Comprobando…")
                        }
                    } else {
                        Text("Volver a comprobar")
                    }
                }
                .buttonStyle(MDCPrimaryButtonStyle(horizontalPadding: 16))
                .disabled(isRechecking)
                .keyboardShortcut(.defaultAction)
            }
            .padding(EdgeInsets(top: 16, leading: 26, bottom: 20, trailing: 26))
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 26))
                .foregroundStyle(Color.mdcCostInk)
                .frame(width: 52, height: 52)
                .background(Color.mdcCostBg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            Text("Cierra estas apps primero")
                .font(.system(size: 17, weight: .bold))
                .padding(.top, 12)
            Text("Limpiar mientras están abiertas puede corromper builds en curso o datos de un simulador.")
                .font(.system(size: 12.5))
                .foregroundStyle(Color.mdcText2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(EdgeInsets(top: 24, leading: 26, bottom: 6, trailing: 26))
    }

    private var list: some View {
        VStack(spacing: 0) {
            ForEach(apps) { app in
                HStack(spacing: 10) {
                    MDCSymbol(name: app.symbol, size: 15)
                        .foregroundStyle(app.tool.map(Color.mdcTool) ?? .mdcText2)
                        .frame(width: 26, height: 26)
                        .background(Color.mdcFill, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    VStack(alignment: .leading, spacing: 0) {
                        Text(app.name)
                            .font(.system(size: 12.5, weight: .semibold))
                        Text(app.detail)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.mdcText3)
                    }
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Abierta")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.mdcCostInk)
                }
                .padding(.horizontal, 14)
                .frame(height: 42)
                .overlay(alignment: .top) {
                    if app.id != apps.first?.id { Rectangle().fill(Color.mdcLine).frame(height: 0.5) }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .mdcInner(radius: 10)
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color.mdcLine, lineWidth: 0.5))
    }
}
