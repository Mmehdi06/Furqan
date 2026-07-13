import SwiftUI

struct NativeGlassPalette {
    let chromeTint: Color?
    let sectionTint: Color?
    let cardFill: AnyShapeStyle
    let elevatedFill: AnyShapeStyle
    let stroke: Color
    let shadow: Color
}

extension ReadingTheme {
    var nativeGlassPalette: NativeGlassPalette {
        switch self {
        case .light:
            return NativeGlassPalette(
                chromeTint: .white.opacity(0.10),
                sectionTint: .white.opacity(0.08),
                cardFill: AnyShapeStyle(.thinMaterial),
                elevatedFill: AnyShapeStyle(.regularMaterial),
                stroke: .black.opacity(0.06),
                shadow: .black.opacity(0.08)
            )
        case .dark:
            return NativeGlassPalette(
                chromeTint: .gray.opacity(0.12),
                sectionTint: .gray.opacity(0.10),
                cardFill: AnyShapeStyle(.thinMaterial),
                elevatedFill: AnyShapeStyle(.regularMaterial),
                stroke: .white.opacity(0.07),
                shadow: .black.opacity(0.22)
            )
        case .sepia:
            return NativeGlassPalette(
                chromeTint: .brown.opacity(0.16),
                sectionTint: .brown.opacity(0.14),
                cardFill: AnyShapeStyle(pageBackground.opacity(0.94)),
                elevatedFill: AnyShapeStyle(pageBackground.opacity(0.98)),
                stroke: Color(red: 0.55, green: 0.45, blue: 0.33).opacity(0.18),
                shadow: .black.opacity(0.10)
            )
        case .amoled:
            return NativeGlassPalette(
                chromeTint: .white.opacity(0.05),
                sectionTint: .white.opacity(0.04),
                cardFill: AnyShapeStyle(Color.white.opacity(0.05)),
                elevatedFill: AnyShapeStyle(Color.white.opacity(0.07)),
                stroke: .white.opacity(0.05),
                shadow: .black.opacity(0.30)
            )
        }
    }
}

private struct AdaptiveGlassMaterialModifier<S: Shape>: ViewModifier {
    let glassTint: Color?
    let shape: S
    let interactive: Bool
    let fallbackFill: AnyShapeStyle
    let fallbackStroke: Color

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(glass, in: shape)
        } else {
            content
                .background(fallbackFill, in: shape)
                .overlay {
                    shape.stroke(fallbackStroke, lineWidth: 0.8)
                }
        }
    }

    @available(iOS 26.0, *)
    private var glass: Glass {
        var glass = Glass.regular

        if let glassTint {
            glass = glass.tint(glassTint)
        }

        if interactive {
            glass = glass.interactive()
        }

        return glass
    }
}

extension View {
    func adaptiveGlass<S: Shape>(
        in shape: S,
        tint: Color? = nil,
        interactive: Bool = false,
        fallbackFill: AnyShapeStyle = AnyShapeStyle(.ultraThinMaterial),
        fallbackStroke: Color = Color.white.opacity(0.12)
    ) -> some View {
        modifier(
            AdaptiveGlassMaterialModifier(
                glassTint: tint,
                shape: shape,
                interactive: interactive,
                fallbackFill: fallbackFill,
                fallbackStroke: fallbackStroke
            )
        )
    }
}

struct AdaptiveGlassCard<Content: View>: View {
    let tint: Color?
    let cornerRadius: CGFloat
    let fallbackFill: AnyShapeStyle
    let fallbackStroke: Color
    let content: Content

    init(
        tint: Color? = nil,
        cornerRadius: CGFloat = 20,
        fallbackFill: AnyShapeStyle = AnyShapeStyle(.ultraThinMaterial),
        fallbackStroke: Color = Color.white.opacity(0.12),
        @ViewBuilder content: () -> Content
    ) {
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.fallbackFill = fallbackFill
        self.fallbackStroke = fallbackStroke
        self.content = content()
    }

    var body: some View {
        content
            .adaptiveGlass(
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous),
                tint: tint,
                fallbackFill: fallbackFill,
                fallbackStroke: fallbackStroke
            )
    }
}

struct AdaptiveGlassCircleButtonStyle: ButtonStyle {
    let tint: Color?
    let fallbackFill: AnyShapeStyle
    let fallbackStroke: Color

    init(
        tint: Color? = nil,
        fallbackFill: AnyShapeStyle = AnyShapeStyle(.ultraThinMaterial),
        fallbackStroke: Color = Color.white.opacity(0.12)
    ) {
        self.tint = tint
        self.fallbackFill = fallbackFill
        self.fallbackStroke = fallbackStroke
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
            .padding(11)
            .adaptiveGlass(
                in: Circle(),
                tint: tint,
                interactive: true,
                fallbackFill: fallbackFill,
                fallbackStroke: fallbackStroke
            )
    }
}

struct NativeGlassSectionCard<Content: View>: View {
    @Environment(\.readingTheme) private var theme
    let cornerRadius: CGFloat
    let tint: Color?
    let elevated: Bool
    let content: Content

    init(
        cornerRadius: CGFloat = 28,
        tint: Color? = nil,
        elevated: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.elevated = elevated
        self.content = content()
    }

    var body: some View {
        let palette = theme.nativeGlassPalette

        content
            .adaptiveGlass(
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous),
                tint: tint ?? palette.sectionTint,
                fallbackFill: elevated ? palette.elevatedFill : palette.cardFill,
                fallbackStroke: palette.stroke
            )
            .shadow(color: palette.shadow, radius: elevated ? 24 : 18, y: elevated ? 10 : 8)
    }
}

struct NativeGlassCapsuleChip<Content: View>: View {
    @Environment(\.readingTheme) private var theme
    let tint: Color?
    let elevated: Bool
    let content: Content

    init(
        tint: Color? = nil,
        elevated: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.tint = tint
        self.elevated = elevated
        self.content = content()
    }

    var body: some View {
        let palette = theme.nativeGlassPalette

        content
            .adaptiveGlass(
                in: Capsule(),
                tint: tint ?? palette.chromeTint,
                fallbackFill: elevated ? palette.elevatedFill : palette.cardFill,
                fallbackStroke: palette.stroke
            )
    }
}

struct NativeGlassRoundedButtonStyle: ButtonStyle {
    @Environment(\.readingTheme) private var theme
    let cornerRadius: CGFloat
    let tint: Color?
    let elevated: Bool

    init(cornerRadius: CGFloat = 18, tint: Color? = nil, elevated: Bool = false) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.elevated = elevated
    }

    func makeBody(configuration: Configuration) -> some View {
        let palette = theme.nativeGlassPalette

        return configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.82), value: configuration.isPressed)
            .adaptiveGlass(
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous),
                tint: tint ?? palette.chromeTint,
                interactive: true,
                fallbackFill: elevated ? palette.elevatedFill : palette.cardFill,
                fallbackStroke: palette.stroke
            )
    }
}
