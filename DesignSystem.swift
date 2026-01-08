import SwiftUI

// 1. Color Mapping for Risk Levels
extension FrostRiskLevel {
    var colors: [Color] {
        switch self {
        case .extreme: return [.indigo, .purple, .blue]
        case .high:    return [.blue, .cyan, .teal]
        case .moderate: return [.cyan, .mint, .teal.opacity(0.5)]
        case .low:     return [.green.opacity(0.6), .mint.opacity(0.4), .clear]
        }
    }
}

// 2. Liquid Glass Modifiers
struct GlassEffect: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    var material: Material = .ultraThin
    
    func body(content: Content) -> some View {
        Group {
            if reduceTransparency {
                content.background(Color(.systemBackground))
            } else {
                content.background(material)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
}

extension View {
    func glassEffect() -> some View { modifier(GlassEffect()) }
    
    func glassEffectUnion() -> some View {
        self
            .background(.thinMaterial)
            .shadow(color: .white.opacity(0.1), radius: 15, x: -5, y: -5)
            .shadow(color: .black.opacity(0.2), radius: 15, x: 5, y: 5)
            .glassEffect()
    }
}
