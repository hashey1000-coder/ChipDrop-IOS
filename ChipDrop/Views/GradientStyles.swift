import SwiftUI

// MARK: - New Theme System — Midnight Emerald

/// Centralized theme with a fresh dark palette: deep charcoal + emerald/lime accents
struct Theme {
    // Core backgrounds
    static let bg = Color(red: 0.06, green: 0.07, blue: 0.10)
    static let surface = Color(red: 0.10, green: 0.12, blue: 0.16)
    static let surfaceLight = Color(red: 0.14, green: 0.16, blue: 0.22)

    // Accent palette
    static let accent = Color(red: 0.30, green: 0.85, blue: 0.55)
    static let accentAlt = Color(red: 0.20, green: 0.70, blue: 1.0)
    static let gold = Color(red: 1.0, green: 0.78, blue: 0.20)
    static let danger = Color(red: 1.0, green: 0.35, blue: 0.35)

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textMuted = Color.white.opacity(0.35)

    // Gradients
    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.15, green: 0.75, blue: 0.45),
            Color(red: 0.10, green: 0.55, blue: 0.90)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.85, blue: 0.30),
            Color(red: 0.95, green: 0.65, blue: 0.15)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let collectGradient = LinearGradient(
        colors: [
            Color(red: 0.20, green: 0.80, blue: 0.50),
            Color(red: 0.15, green: 0.65, blue: 0.85)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let chipCardGradient = LinearGradient(
        colors: [
            Color(red: 0.12, green: 0.65, blue: 0.40),
            Color(red: 0.08, green: 0.45, blue: 0.70),
            Color(red: 0.20, green: 0.30, blue: 0.55)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Glow Ring Modifier

struct GlowRing: ViewModifier {
    @State private var phase: CGFloat = 0
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        AngularGradient(
                            colors: [
                                Theme.accent,
                                Theme.accentAlt,
                                Theme.gold,
                                Theme.accent,
                            ],
                            center: .center,
                            angle: .degrees(phase)
                        ),
                        lineWidth: 2.5
                    )
                    .blur(radius: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        AngularGradient(
                            colors: [
                                Theme.accent.opacity(0.6),
                                Theme.accentAlt.opacity(0.6),
                                Theme.gold.opacity(0.6),
                                Theme.accent.opacity(0.6),
                            ],
                            center: .center,
                            angle: .degrees(phase)
                        ),
                        lineWidth: 1
                    )
            )
            .onAppear {
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    phase = 360
                }
            }
    }
}

extension View {
    func glowRing(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlowRing(cornerRadius: cornerRadius))
    }
}

// MARK: - Pill Tag

struct PillTag: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .heavy))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(color))
    }
}

// MARK: - Compat shim so old refs still compile
struct AppGradients {
    static let background = Theme.bg
    static let tileBackground = Theme.surface
    static let accentPink = Theme.accent
    static let collectButton = Theme.collectGradient
    static let cardGradient = Theme.heroGradient
    static let newBadgeColor = Theme.danger
}
