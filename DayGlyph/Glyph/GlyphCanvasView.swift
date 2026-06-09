import SwiftUI

struct GlyphCanvasView: View {
    var signature: GlyphSignature
    var lineWidth: CGFloat = 4

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = min(size.width, size.height) * 0.34

            drawBadge(in: rect, context: &context)
            drawBase(center: center, radius: radius, context: &context)
            drawAccents(center: center, radius: radius, context: &context)
            drawCore(center: center, radius: radius, context: &context)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("\(signature.emotion.title)情绪符号")
    }

    private func drawBadge(in rect: CGRect, context: inout GraphicsContext) {
        let inset = rect.width * 0.08
        let badge = RoundedRectangle(cornerRadius: rect.width * 0.22, style: .continuous)
            .path(in: rect.insetBy(dx: inset, dy: inset))
        context.fill(
            badge,
            with: .linearGradient(
                Gradient(colors: [signature.palette.background, signature.palette.background.opacity(0.72)]),
                startPoint: CGPoint(x: rect.minX, y: rect.minY),
                endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
            )
        )
        context.stroke(badge, with: .color(.white.opacity(0.72)), lineWidth: max(lineWidth * 0.35, 1))
    }

    private func drawBase(center: CGPoint, radius: CGFloat, context: inout GraphicsContext) {
        switch signature.baseShape {
        case .calmRing, .warmOrbit, .heldArc:
            drawRing(center: center, radius: radius, context: &context)
        case .lowPool, .quietBlock:
            drawSoftBlock(center: center, radius: radius, context: &context)
        case .offsetOrbit, .layered:
            drawOffsetRings(center: center, radius: radius, context: &context)
        case .radiantSeal:
            drawRadiantCapsules(center: center, radius: radius, context: &context)
        }
    }

    private func drawRing(center: CGPoint, radius: CGFloat, context: inout GraphicsContext) {
        var outer = Path()
        outer.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        context.stroke(outer, with: .color(signature.palette.primary), lineWidth: lineWidth * 1.8)

        var arc = Path()
        arc.addArc(
            center: center,
            radius: radius * 0.72,
            startAngle: .degrees(signature.rotation),
            endAngle: .degrees(signature.rotation + 220),
            clockwise: false
        )
        context.stroke(arc, with: .color(signature.palette.secondary), lineWidth: lineWidth * 1.15)
    }

    private func drawSoftBlock(center: CGPoint, radius: CGFloat, context: inout GraphicsContext) {
        let rect = CGRect(
            x: center.x - radius * 0.78,
            y: center.y - radius * 0.62,
            width: radius * 1.56,
            height: radius * 1.24
        )
        let block = RoundedRectangle(cornerRadius: radius * 0.34, style: .continuous).path(in: rect)
        context.fill(block, with: .color(signature.palette.secondary.opacity(0.30)))
        context.stroke(block, with: .color(signature.palette.primary), lineWidth: lineWidth * 1.35)
    }

    private func drawOffsetRings(center: CGPoint, radius: CGFloat, context: inout GraphicsContext) {
        drawRing(center: center, radius: radius, context: &context)
        let offset = radius * 0.16
        var second = Path()
        second.addEllipse(
            in: CGRect(
                x: center.x - radius * 0.72 + offset,
                y: center.y - radius * 0.72 - offset,
                width: radius * 1.44,
                height: radius * 1.44
            )
        )
        context.stroke(second, with: .color(signature.palette.accent.opacity(0.74)), lineWidth: lineWidth)
    }

    private func drawRadiantCapsules(center: CGPoint, radius: CGFloat, context: inout GraphicsContext) {
        for index in 0..<signature.accentCount {
            let angle = (Double(index) / Double(signature.accentCount)) * .pi * 2 + signature.rotation * .pi / 180
            let length = radius * (0.26 + signature.density * 0.12)
            let capsuleCenter = CGPoint(x: center.x + cos(angle) * radius * 0.72, y: center.y + sin(angle) * radius * 0.72)
            let rect = CGRect(x: capsuleCenter.x - lineWidth * 0.75, y: capsuleCenter.y - length / 2, width: lineWidth * 1.5, height: length)
            var copy = context
            copy.translateBy(x: capsuleCenter.x, y: capsuleCenter.y)
            copy.rotate(by: .radians(angle))
            copy.translateBy(x: -capsuleCenter.x, y: -capsuleCenter.y)
            copy.fill(
                RoundedRectangle(cornerRadius: lineWidth, style: .continuous).path(in: rect),
                with: .color(signature.palette.primary.opacity(0.86))
            )
        }
    }

    private func drawAccents(center: CGPoint, radius: CGFloat, context: inout GraphicsContext) {
        for index in 0..<signature.accentCount {
            let progress = Double(index) / Double(max(signature.accentCount, 1))
            let angle = progress * .pi * 2 + signature.rotation * .pi / 180
            let distance = radius * (0.34 + 0.34 * signature.density)
            let point = CGPoint(x: center.x + cos(angle) * distance, y: center.y + sin(angle) * distance)
            drawAccent(at: point, angle: angle, radius: radius, context: &context)
        }
    }

    private func drawAccent(at point: CGPoint, angle: Double, radius: CGFloat, context: inout GraphicsContext) {
        switch signature.accentShape {
        case .dot:
            let dot = radius * 0.07
            context.fill(
                Path(ellipseIn: CGRect(x: point.x - dot, y: point.y - dot, width: dot * 2, height: dot * 2)),
                with: .color(signature.palette.accent)
            )
        case .capsule:
            let rect = CGRect(x: point.x - radius * 0.045, y: point.y - radius * 0.16, width: radius * 0.09, height: radius * 0.32)
            var copy = context
            copy.translateBy(x: point.x, y: point.y)
            copy.rotate(by: .radians(angle))
            copy.translateBy(x: -point.x, y: -point.y)
            copy.fill(RoundedRectangle(cornerRadius: radius * 0.045, style: .continuous).path(in: rect), with: .color(signature.palette.accent))
        case .arc:
            var arc = Path()
            arc.addArc(center: point, radius: radius * 0.13, startAngle: .degrees(20), endAngle: .degrees(210), clockwise: false)
            context.stroke(arc, with: .color(signature.palette.accent), lineWidth: lineWidth * 0.8)
        case .notch:
            let rect = CGRect(x: point.x - radius * 0.08, y: point.y - radius * 0.08, width: radius * 0.16, height: radius * 0.16)
            context.fill(RoundedRectangle(cornerRadius: radius * 0.035, style: .continuous).path(in: rect), with: .color(signature.palette.accent))
        }
    }

    private func drawCore(center: CGPoint, radius: CGFloat, context: inout GraphicsContext) {
        let coreRadius = radius * (0.16 + signature.confidence * 0.06)
        context.fill(
            Path(ellipseIn: CGRect(x: center.x - coreRadius, y: center.y - coreRadius, width: coreRadius * 2, height: coreRadius * 2)),
            with: .color(signature.palette.primary)
        )
        context.fill(
            Path(
                ellipseIn: CGRect(
                    x: center.x - coreRadius * 0.42,
                    y: center.y - coreRadius * 0.42,
                    width: coreRadius * 0.84,
                    height: coreRadius * 0.84
                )
            ),
            with: .color(signature.palette.background.opacity(0.86))
        )
    }
}

#Preview {
    GlyphCanvasView(
        signature: GlyphSignature(
            analysis: EmotionAnalysis(
                emotion: .calm,
                theme: .rest,
                energy: 0.4,
                keywords: ["休息"],
                confidence: 0.7,
                explanation: "平静。",
                source: .localRules
            ),
            seed: 24
        )
    )
    .padding()
}
