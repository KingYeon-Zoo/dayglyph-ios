import SwiftUI

struct GlyphCanvasView: View {
    var signature: GlyphSignature
    var lineWidth: CGFloat = 4

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = min(size.width, size.height) * 0.36
            var random = SeededRandom(seed: signature.seed)

            drawBackground(in: rect, context: &context)

            switch signature.motif {
            case .arcs:
                drawArcs(center: center, radius: radius, random: &random, context: &context)
            case .radiant:
                drawRadiant(center: center, radius: radius, random: &random, context: &context)
            case .folded:
                drawFolded(center: center, radius: radius, random: &random, context: &context)
            case .dotted:
                drawDotted(center: center, radius: radius, random: &random, context: &context)
            case .wave:
                drawWave(center: center, radius: radius, random: &random, context: &context)
            case .hybrid:
                drawArcs(center: center, radius: radius, random: &random, context: &context)
                drawDotted(center: center, radius: radius * 0.85, random: &random, context: &context)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("\(signature.emotion.title)情绪符文")
    }

    private func drawBackground(in rect: CGRect, context: inout GraphicsContext) {
        let path = Path(ellipseIn: rect.insetBy(dx: rect.width * 0.08, dy: rect.height * 0.08))
        context.fill(path, with: .color(signature.secondaryColor.opacity(0.18)))
    }

    private func drawArcs(center: CGPoint, radius: CGFloat, random: inout SeededRandom, context: inout GraphicsContext) {
        for index in 0..<signature.strokeCount {
            let startDegrees = Double(index) * 28 + random.next() * 18 + signature.rotation
            let start = Angle.degrees(startDegrees)
            let end = Angle.degrees(startDegrees + 70 + random.next() * 80)
            var path = Path()
            path.addArc(
                center: center,
                radius: radius * (0.55 + CGFloat(random.next()) * 0.55),
                startAngle: start,
                endAngle: end,
                clockwise: false
            )
            context.stroke(path, with: .color(index.isMultiple(of: 2) ? signature.primaryColor : signature.secondaryColor), lineWidth: lineWidth)
        }
    }

    private func drawRadiant(center: CGPoint, radius: CGFloat, random: inout SeededRandom, context: inout GraphicsContext) {
        for index in 0..<signature.strokeCount {
            let angle = (Double(index) / Double(max(signature.strokeCount, 1))) * .pi * 2 + random.next()
            let inner = radius * (0.16 + CGFloat(random.next()) * 0.24)
            let outer = radius * (0.65 + CGFloat(random.next()) * 0.45)
            var path = Path()
            path.move(to: CGPoint(x: center.x + CGFloat(cos(angle)) * inner, y: center.y + CGFloat(sin(angle)) * inner))
            path.addLine(to: CGPoint(x: center.x + CGFloat(cos(angle)) * outer, y: center.y + CGFloat(sin(angle)) * outer))
            context.stroke(path, with: .color(index.isMultiple(of: 2) ? signature.primaryColor : signature.secondaryColor), lineWidth: lineWidth)
        }
    }

    private func drawFolded(center: CGPoint, radius: CGFloat, random: inout SeededRandom, context: inout GraphicsContext) {
        var path = Path()
        for index in 0...signature.strokeCount {
            let progress = Double(index) / Double(max(signature.strokeCount, 1))
            let angle = progress * .pi * 2 + signature.rotation * .pi / 180
            let localRadius = radius * (0.28 + CGFloat(random.next()) * 0.72)
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * localRadius, y: center.y + CGFloat(sin(angle)) * localRadius)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        context.stroke(path, with: .color(signature.primaryColor), lineWidth: lineWidth)
    }

    private func drawDotted(center: CGPoint, radius: CGFloat, random: inout SeededRandom, context: inout GraphicsContext) {
        for _ in 0..<(signature.strokeCount + 3) {
            let angle = random.next() * .pi * 2
            let distance = radius * (0.18 + CGFloat(random.next()) * 0.82)
            let dotRadius = CGFloat(3 + random.next() * 8) * max(lineWidth / 4, 0.7)
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * distance, y: center.y + CGFloat(sin(angle)) * distance)
            context.fill(
                Path(ellipseIn: CGRect(x: point.x - dotRadius, y: point.y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)),
                with: .color(signature.primaryColor.opacity(0.78))
            )
        }
    }

    private func drawWave(center: CGPoint, radius: CGFloat, random: inout SeededRandom, context: inout GraphicsContext) {
        for band in 0..<3 {
            var path = Path()
            let yOffset = CGFloat(band - 1) * radius * 0.26
            let phase = CGFloat(signature.rotation) / 90
            let amplitude = radius * (0.12 + CGFloat(random.next()) * 0.05)
            for step in 0...40 {
                let x = center.x - radius + CGFloat(step) / 40 * radius * 2
                let wave = sin(CGFloat(step) / 40 * .pi * 2 + phase) * amplitude
                let point = CGPoint(x: x, y: center.y + yOffset + wave)
                if step == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            context.stroke(path, with: .color(band == 1 ? signature.primaryColor : signature.secondaryColor), lineWidth: lineWidth)
        }
    }
}

#Preview {
    GlyphCanvasView(signature: GlyphSignature(analysis: EmotionAnalysis(emotion: .calm, theme: .rest, energy: 0.4, keywords: ["休息"]), seed: 24))
        .padding()
}
