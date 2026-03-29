import SwiftUI

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
                    shape
                        .stroke(fallbackStroke, lineWidth: 0.8)
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
    let content: Content

    init(
        tint: Color? = nil,
        cornerRadius: CGFloat = 20,
        fallbackFill: AnyShapeStyle = AnyShapeStyle(.ultraThinMaterial),
        @ViewBuilder content: () -> Content
    ) {
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.fallbackFill = fallbackFill
        self.content = content()
    }

    var body: some View {
        content
            .adaptiveGlass(
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous),
                tint: tint,
                fallbackFill: fallbackFill
            )
    }
}

struct AdaptiveGlassCircleButtonStyle: ButtonStyle {
    let tint: Color?

    init(tint: Color? = nil) {
        self.tint = tint
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
            .padding(10)
            .adaptiveGlass(
                in: Circle(),
                tint: tint,
                interactive: true,
                fallbackFill: AnyShapeStyle(.ultraThinMaterial)
            )
    }
}

struct AdaptiveGlassProminentButtonStyle: ButtonStyle {
    let tint: Color?

    init(tint: Color? = nil) {
        self.tint = tint
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .adaptiveGlass(
                in: Capsule(),
                tint: tint,
                interactive: true,
                fallbackFill: AnyShapeStyle(.regularMaterial)
            )
    }
}
