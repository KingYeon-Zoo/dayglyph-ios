import RealityKit
import SwiftUI
import UIKit

struct UniverseRealityView: View {
    var visual: MonthlyPlanetVisual
    var onSelectDate: (Date) -> Void
    var onSceneFailure: () -> Void

    private var descriptor: UniverseSceneDescriptor {
        UniverseSceneDescriptor.make(visual: visual)
    }

    var body: some View {
        RealityView { content in
            guard Task.isCancelled == false else {
                onSceneFailure()
                return
            }
            let root = makeScene()
            content.add(root)
            content.camera = .virtual
            content.cameraTarget = root
        } placeholder: {
            ProgressView("正在形成月星球")
                .tint(.white)
                .foregroundStyle(.white.opacity(0.72))
        }
        .realityViewCameraControls(.orbit)
        .gesture(
            TapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    guard let dot = descriptor.recordDots.first(where: {
                        $0.entityName == value.entity.name
                    }) else { return }
                    onSelectDate(dot.date)
                }
        )
        .accessibilityHidden(true)
    }

    private func makeScene() -> Entity {
        let root = Entity()
        root.name = "month-planet-root"
        root.position = [0, 0, -3]

        let planetRadius = Float(descriptor.sizeScale)
        var planetMaterial = PhysicallyBasedMaterial()
        planetMaterial.baseColor = .init(tint: color(hue: descriptor.baseHue))
        planetMaterial.roughness = .init(floatLiteral: 0.34)
        planetMaterial.metallic = .init(floatLiteral: 0.12)
        let planet = ModelEntity(
            mesh: .generateSphere(radius: planetRadius),
            materials: [planetMaterial]
        )
        planet.name = "month-planet"
        root.addChild(planet)

        var atmosphereMaterial = PhysicallyBasedMaterial()
        atmosphereMaterial.baseColor = .init(
            tint: color(hue: descriptor.secondaryHue).withAlphaComponent(0.20)
        )
        atmosphereMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.22))
        atmosphereMaterial.roughness = 0.16
        let atmosphere = ModelEntity(
            mesh: .generateSphere(radius: planetRadius * 1.035),
            materials: [atmosphereMaterial]
        )
        atmosphere.name = "month-atmosphere"
        root.addChild(atmosphere)

        for dot in descriptor.recordDots {
            let entity = ModelEntity(
                mesh: .generateSphere(radius: 0.045),
                materials: [UnlitMaterial(color: .white)]
            )
            entity.name = dot.entityName
            entity.position = dot.position
            entity.components.set(InputTargetComponent())
            entity.components.set(
                CollisionComponent(shapes: [.generateSphere(radius: dot.hitRadius)])
            )
            root.addChild(entity)
        }

        for index in 0 ..< descriptor.satellites {
            let satellite = ModelEntity(
                mesh: .generateSphere(radius: 0.10 - Float(index) * 0.012),
                materials: [
                    SimpleMaterial(
                        color: color(hue: descriptor.secondaryHue + Double(index) * 22),
                        roughness: 0.4,
                        isMetallic: true
                    )
                ]
            )
            let angle = Float(index + 1) * 2.1
            let distance = Float(1.42 + Double(index) * 0.16)
            satellite.position = [cos(angle) * distance, sin(angle * 0.7) * 0.52, sin(angle) * distance]
            root.addChild(satellite)
        }

        startRotation(on: root)
        return root
    }

    private func startRotation(on entity: Entity) {
        let duration = max(24, 60 / descriptor.rotationSpeed)
        let animation = OrbitAnimation(
            duration: duration,
            axis: [0, 1, 0],
            startTransform: entity.transform,
            spinClockwise: descriptor.seed.isMultiple(of: 2),
            orientToPath: false,
            rotationCount: 1,
            repeatMode: .repeat
        )
        if let resource = try? AnimationResource.generate(with: animation) {
            entity.playAnimation(resource)
        }
    }

    private func color(hue: Double) -> UIColor {
        let normalized = hue.truncatingRemainder(dividingBy: 360)
        return UIColor(
            hue: normalized < 0 ? (normalized + 360) / 360 : normalized / 360,
            saturation: 0.68,
            brightness: 0.92,
            alpha: 1
        )
    }
}
