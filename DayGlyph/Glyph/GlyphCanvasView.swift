import SwiftUI

enum GlyphDisplayMode: Equatable {
    case thumbnail
    case hero
    case detail

    var rhythmLimit: Int {
        switch self {
        case .thumbnail: 6
        case .hero, .detail: 12
        }
    }

    var showsAmbientGlow: Bool {
        self != .thumbnail
    }
}

struct GlyphCanvasView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var signature: GlyphSignature
    var lineWidth: CGFloat = 4
    var mode: GlyphDisplayMode = .detail
    var revealProgress: Double = 1

    @State private var glowExpanded = false

    var body: some View {
        ZStack {
            if mode.showsAmbientGlow {
                Circle()
                    .fill(signature.palette.secondary.opacity(0.18))
                    .blur(radius: 24)
                    .scaleEffect(glowExpanded ? 1.08 : 0.92)
                    .opacity(glowExpanded ? 0.72 : 0.42)
                    .padding(20)
            }

            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size)
                let center = CGPoint(x: rect.midX, y: rect.midY)
                let radius = min(size.width, size.height) * 0.32

                drawBadge(in: rect, context: &context)
                drawBoundary(center: center, radius: radius, context: &context)
                drawTrajectory(center: center, radius: radius, context: &context)
                drawCore(center: center, radius: radius, context: &context)
                drawRhythm(center: center, radius: radius, context: &context)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            guard mode.showsAmbientGlow, !reduceMotion else {
                glowExpanded = true
                return
            }
            withAnimation(.easeInOut(duration: 4.2).repeatForever(autoreverses: true)) {
                glowExpanded = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(signature.primaryEmotion.title)情绪印记")
        .accessibilityValue("唤醒度 \(Int(signature.energy * 100))%，置信度 \(Int(signature.confidence * 100))%")
    }

    private var boundaryProgress: Double {
        stagedProgress(from: 0, to: 0.28)
    }

    private var trajectoryProgress: Double {
        stagedProgress(from: 0.2, to: 0.58)
    }

    private var coreProgress: Double {
        stagedProgress(from: 0.5, to: 0.78)
    }

    private var rhythmProgress: Double {
        stagedProgress(from: 0.7, to: 1)
    }

    private func stagedProgress(from start: Double, to end: Double) -> Double {
        min(max((revealProgress - start) / (end - start), 0), 1)
    }

    private func drawBadge(in rect: CGRect, context: inout GraphicsContext) {
        let inset = rect.width * (mode == .thumbnail ? 0.045 : 0.055)
        let badgeRect = rect.insetBy(dx: inset, dy: inset)
        let badge = RoundedRectangle(cornerRadius: rect.width * 0.235, style: .continuous)
            .path(in: badgeRect)

        context.fill(
            badge,
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: signature.palette.background.opacity(0.96), location: 0),
                    .init(color: signature.palette.background.opacity(0.76), location: 0.58),
                    .init(color: signature.palette.secondary.opacity(0.18), location: 1)
                ]),
                startPoint: CGPoint(x: badgeRect.minX, y: badgeRect.minY),
                endPoint: CGPoint(x: badgeRect.maxX, y: badgeRect.maxY)
            )
        )
        context.stroke(
            badge,
            with: .linearGradient(
                Gradient(colors: [.white.opacity(0.92), signature.palette.secondary.opacity(0.28)]),
                startPoint: badgeRect.origin,
                endPoint: CGPoint(x: badgeRect.maxX, y: badgeRect.maxY)
            ),
            lineWidth: max(lineWidth * 0.24, 0.8)
        )
    }

    private func drawBoundary(center: CGPoint, radius: CGFloat, context: inout GraphicsContext) {
        guard boundaryProgress > 0 else { return }

        let boundary = signature.boundary
        let sweep = (.pi * 2) * (0.64 + boundary.closure * 0.36) * boundaryProgress
        let start = -.pi / 2 + signature.microRotation * .pi / 180
        let steps = max(Int(56 * boundaryProgress), 3)
        var path = Path()

        for index in 0...steps {
            let fraction = Double(index) / Double(steps)
            let angle = start + sweep * fraction
            let angularWave = sin(angle * 5 + Double(signature.seed % 17))
            let deformation = 1 + angularWave * boundary.angularity * 0.08
            let xRadius = radius * (1 + boundary.eccentricity * 0.2)
            let yRadius = radius * (1 - boundary.eccentricity * 0.15)
            let point = CGPoint(
                x: center.x + cos(angle) * xRadius * deformation,
                y: center.y + sin(angle) * yRadius * deformation
            )

            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        context.stroke(
            path,
            with: .color(signature.palette.primary.opacity(0.96)),
            style: StrokeStyle(
                lineWidth: lineWidth * (1.12 + boundary.thickness * 0.9),
                lineCap: boundary.roundness > 0.5 ? .round : .square,
                lineJoin: boundary.roundness > 0.55 ? .round : .bevel
            )
        )
    }

    private func drawTrajectory(center: CGPoint, radius: CGFloat, context: inout GraphicsContext) {
        guard trajectoryProgress > 0 else { return }

        let trajectory = signature.trajectory
        let halfWidth = radius * (0.4 + trajectory.openness * 0.42)
        let baseline = center.y - radius * CGFloat(trajectory.verticalBias) * 0.28
        let amplitude = radius * CGFloat(0.08 + trajectory.oscillation * 0.23)
        let visibleSteps = max(Int(44 * trajectoryProgress), 3)
        var path = Path()

        for index in 0...visibleSteps {
            let fraction = Double(index) / 44
            let normalizedX = fraction * 2 - 1
            let x = center.x + CGFloat(normalizedX) * halfWidth
            let wave = sin(
                normalizedX * .pi * (1.15 + trajectory.oscillation * 2.6)
                    + signature.microRotation * .pi / 90
            )
            let bow = (1 - normalizedX * normalizedX) * (trajectory.curvature - 0.5)
            let y = baseline - CGFloat(wave) * amplitude - CGFloat(bow) * radius * 0.18
            let point = CGPoint(x: x, y: y)

            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        context.stroke(
            path,
            with: .color(signature.palette.secondary.opacity(0.94)),
            style: StrokeStyle(
                lineWidth: lineWidth * 0.92,
                lineCap: .round,
                lineJoin: .round
            )
        )

        guard trajectory.crossing > 0.18, trajectoryProgress > 0.72 else { return }
        var crossing = Path()
        crossing.move(
            to: CGPoint(
                x: center.x - halfWidth * 0.48,
                y: baseline - radius * CGFloat(trajectory.crossing) * 0.18
            )
        )
        crossing.addCurve(
            to: CGPoint(
                x: center.x + halfWidth * 0.48,
                y: baseline + radius * CGFloat(trajectory.crossing) * 0.18
            ),
            control1: CGPoint(x: center.x + halfWidth * 0.1, y: baseline - radius * 0.28),
            control2: CGPoint(x: center.x - halfWidth * 0.1, y: baseline + radius * 0.28)
        )
        context.stroke(
            crossing,
            with: .color(signature.palette.accent.opacity(0.72)),
            style: StrokeStyle(lineWidth: lineWidth * 0.58, lineCap: .round)
        )
    }

    private func drawCore(center: CGPoint, radius: CGFloat, context: inout GraphicsContext) {
        guard coreProgress > 0 else { return }

        let core = signature.core
        let coreCenter = CGPoint(
            x: center.x + radius * CGFloat(core.offsetX) * 0.62,
            y: center.y + radius * CGFloat(core.offsetY) * 0.62
        )
        let outerRadius = radius * CGFloat(core.scale) * CGFloat(0.72 + coreProgress * 0.28)
        let isolationOpacity = 0.92 - core.isolation * 0.3

        context.fill(
            Path(
                ellipseIn: CGRect(
                    x: coreCenter.x - outerRadius,
                    y: coreCenter.y - outerRadius,
                    width: outerRadius * 2,
                    height: outerRadius * 2
                )
            ),
            with: .color(signature.palette.primary.opacity(isolationOpacity))
        )

        let innerRadius = outerRadius * (0.32 + core.isolation * 0.18)
        context.fill(
            Path(
                ellipseIn: CGRect(
                    x: coreCenter.x - innerRadius,
                    y: coreCenter.y - innerRadius,
                    width: innerRadius * 2,
                    height: innerRadius * 2
                )
            ),
            with: .color(signature.palette.background.opacity(0.92))
        )
    }

    private func drawRhythm(center: CGPoint, radius: CGFloat, context: inout GraphicsContext) {
        guard rhythmProgress > 0 else { return }

        let rhythm = signature.rhythm
        let totalCount = min(rhythm.count, mode.rhythmLimit)
        let visibleCount = min(Int(ceil(Double(totalCount) * rhythmProgress)), totalCount)
        guard visibleCount > 0 else { return }

        for index in 0..<visibleCount {
            let regularAngle = Double(index) / Double(max(totalCount, 1)) * .pi * 2
            let irregular = sin(Double(index * 17 + signature.seed % 29)) * (1 - rhythm.regularity) * 0.34
            let angle = regularAngle + irregular + signature.microRotation * .pi / 180
            let spreadWave = cos(Double(index * 11 + signature.seed % 13))
            let distance = radius * CGFloat(
                0.48 + rhythm.radialSpread * 0.24 + spreadWave * (1 - rhythm.regularity) * 0.1
            )
            let point = CGPoint(
                x: center.x + cos(angle) * distance,
                y: center.y + sin(angle) * distance
            )
            drawRhythmMark(
                at: point,
                angle: angle,
                radius: radius,
                index: index,
                context: &context
            )
        }
    }

    private func drawRhythmMark(
        at point: CGPoint,
        angle: Double,
        radius: CGFloat,
        index: Int,
        context: inout GraphicsContext
    ) {
        let burst = signature.rhythm.burst
        let markLength = radius * CGFloat(0.07 + burst * 0.15)
        let markWidth = max(lineWidth * CGFloat(0.5 + burst * 0.32), 1.2)

        if burst > 0.46 || index.isMultiple(of: 3) {
            let start = CGPoint(
                x: point.x - cos(angle) * markLength * 0.5,
                y: point.y - sin(angle) * markLength * 0.5
            )
            let end = CGPoint(
                x: point.x + cos(angle) * markLength * 0.5,
                y: point.y + sin(angle) * markLength * 0.5
            )
            var path = Path()
            path.move(to: start)
            path.addLine(to: end)
            context.stroke(
                path,
                with: .color(signature.palette.accent.opacity(0.9)),
                style: StrokeStyle(lineWidth: markWidth, lineCap: .round)
            )
        } else {
            let dotRadius = markWidth * 0.58
            context.fill(
                Path(
                    ellipseIn: CGRect(
                        x: point.x - dotRadius,
                        y: point.y - dotRadius,
                        width: dotRadius * 2,
                        height: dotRadius * 2
                    )
                ),
                with: .color(signature.palette.accent.opacity(0.88))
            )
        }
    }
}

#Preview {
    GlyphCanvasView(
        signature: GlyphSignature(
            analysis: EmotionAnalysis(
                valence: -0.72,
                arousal: 0.86,
                dominance: 0.55,
                emotionWeights: [
                    EmotionWeight(anchor: .angry, value: 0.72),
                    EmotionWeight(anchor: .anxious, value: 0.28)
                ],
                theme: .work,
                keywords: ["冲突", "压力"],
                confidence: 0.86,
                explanation: "高唤醒、高掌控感让边界更尖锐，节律向外爆发。",
                source: .foundationModel
            ),
            seed: 24
        ),
        lineWidth: 5,
        mode: .hero
    )
    .padding()
}
