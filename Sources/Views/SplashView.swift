import SwiftUI

struct SplashView: View {
    private let barHeights: [CGFloat] = [0.38, 0.62, 0.27, 0.50]
    private let barOpacities: [Double] = [0.50, 0.92, 0.40, 0.72]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Dégradé — identique à l'icône et au launch screen
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.42, blue: 0.95),
                        Color(red: 0.48, green: 0.18, blue: 0.92),
                    ],
                    startPoint: UnitPoint(x: 0.1, y: 0),
                    endPoint:   UnitPoint(x: 0.9, y: 1)
                )
                .ignoresSafeArea()

                // Cercles glassmorphisme
                Circle()
                    .fill(.white.opacity(0.07))
                    .frame(width: geo.size.width * 1.1)
                    .offset(x: geo.size.width * 0.25, y: geo.size.height * 0.15)
                Circle()
                    .fill(.white.opacity(0.04))
                    .frame(width: geo.size.width * 0.9)
                    .offset(x: -geo.size.width * 0.25, y: -geo.size.height * 0.2)

                VStack(spacing: 0) {
                    // Texte
                    Text("MINI")
                        .font(.system(size: 72, weight: .black))
                        .foregroundStyle(.white.opacity(0.97))
                        .tracking(4)

                    Text("COMPTA")
                        .font(.system(size: 54, weight: .bold))
                        .foregroundStyle(.white.opacity(0.95))
                        .tracking(4)

                    // Séparateur
                    Rectangle()
                        .fill(.white.opacity(0.35))
                        .frame(width: 120, height: 1.5)
                        .padding(.top, 10)
                        .padding(.bottom, 12)

                    // Barres
                    let barAreaH = geo.size.height * 0.28
                    HStack(alignment: .bottom, spacing: geo.size.width * 0.04) {
                        ForEach(Array(barHeights.enumerated()), id: \.offset) { i, ratio in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white.opacity(barOpacities[i]))
                                .frame(width: geo.size.width * 0.12,
                                       height: barAreaH * ratio)
                        }
                    }
                    .frame(height: barAreaH, alignment: .bottom)

                    // Ligne de base
                    Rectangle()
                        .fill(.white.opacity(0.28))
                        .frame(height: 1.5)
                        .padding(.horizontal, geo.size.width * 0.15)
                }
            }
        }
    }
}
