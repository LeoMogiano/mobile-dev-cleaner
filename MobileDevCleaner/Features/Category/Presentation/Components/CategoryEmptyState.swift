import SwiftUI

struct CategoryEmptyState: View {
    let symbol: String

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: symbol)
                .font(.system(size: 28))
                .foregroundStyle(Color.mdcText3)
                .frame(width: 64, height: 64)
                .background(Color.mdcFill, in: Circle())
            Text("No encontrado")
                .font(.system(size: 15, weight: .semibold))
                .padding(.top, 14)
            Text("No hay nada de esta categoría en tu Mac.")
                .font(.system(size: 12.5))
                .foregroundStyle(Color.mdcText2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
    }
}
