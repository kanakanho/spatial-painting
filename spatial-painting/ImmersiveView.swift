//
//  ImmersiveView.swift
//  spatial-painting
//
//  Created by blueken on 2025/03/18.
//

import SwiftUI
import ARKit
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    
    @Environment(ViewModel.self) var model
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.openWindow) var openWindow

    @State var lastIndexPose: SIMD3<Float>?

    var body: some View {
        RealityView { content in
            do {
                let scene = try await Entity(named: "Immersive", in: realityKitContentBundle)
                model.colorPaletModel.setSceneEntity(scene: scene)

                content.add(model.setupContentEntity())
                content.add(model.colorPaletModel.colorPaletEntity)
                let root = model.canvas.root
                content.add(root)

                // added by nagao 3/22
                for fingerEntity in model.fingerEntities.values {
                    //print("Collision Setting for \(fingerEntity.name)")
                    _ = content.subscribe(to: CollisionEvents.Began.self, on: fingerEntity) { collisionEvent in
                        if model.colorPaletModel.colorNames.contains(collisionEvent.entityB.name) {
                            model.changeFingerColor(entity: fingerEntity, colorName: collisionEvent.entityB.name)
                            //print("💥 Collision between \(collisionEvent.entityA.name) and \(collisionEvent.entityB.name) began")
                        } else if (collisionEvent.entityB.name == "clear") {
                            _ = model.recordTime(isBegan: true)
                        }
                    }

                    _ = content.subscribe(to: CollisionEvents.Ended.self, on: fingerEntity) { collisionEvent in
                        if model.colorPaletModel.colorNames.contains(collisionEvent.entityB.name) {
                            model.selectColor(colorName: collisionEvent.entityB.name)
                            //print("💥 Collision between \(collisionEvent.entityA.name) and \(collisionEvent.entityB.name) ended")
                        } else if (collisionEvent.entityB.name == "clear") {
                            if model.recordTime(isBegan: false) {
                                for stroke in model.canvas.strokes {
                                    stroke.entity.removeFromParent()
                                }
                                model.canvas.strokes.removeAll()
                            }
                        }
                    }
                }

                root.components.set(ClosureComponent(closure: { deltaTime in
                    var anchors = [HandAnchor]()
                    
                    if let left = model.latestHandTracking.left {
                        anchors.append(left)
                    }
                    
                    if let right = model.latestHandTracking.right {
                        anchors.append(right)
                    }
                    
                    // Loop through each anchor the app detects.
                    for anchor in anchors {
                        /// The hand skeleton that associates the anchor.
                        guard let handSkeleton = anchor.handSkeleton else {
                            continue
                        }

                        /// The current position and orientation of the thumb tip.
                        let thumbPos = (
                            anchor.originFromAnchorTransform * handSkeleton.joint(.thumbTip).anchorFromJointTransform).translation()

                        /// The current position and orientation of the index finger tip.
                        let indexPos = (anchor.originFromAnchorTransform * handSkeleton.joint(.indexFingerTip).anchorFromJointTransform).translation()

                        /// The threshold to check if the index and thumb are close.
                        let pinchThreshold: Float = 0.03

                        // Update the last index position if the distance
                        // between the thumb tip and index finger tip is
                        // less than the pinch threshold.
                        if length(thumbPos - indexPos) < pinchThreshold {
                            lastIndexPose = indexPos
                        }
                    }
                }))
            } catch {
                print("Error in RealityView's make: \(error)")
            }
        }
        .task {
            //model.webSocketClient.connect()
            do {
                try await model.session.run([model.sceneReconstruction, model.handTracking])
            } catch {
                print("Failed to start session: \(error)")
                await dismissImmersiveSpace()
                openWindow(id: "error")
            }
        }
        .task {
            await model.processHandUpdates()
        }
        .task(priority: .low) {
            await model.processReconstructionUpdates()
        }
        .task {
            await model.monitorSessionEvents()
        }
        .task {
            await model.processWorldUpdates()
        }
        .task {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                model.colorPaletModel.initEntity()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .targetedToAnyEntity()
                .onChanged({ _ in
                    if let pos = lastIndexPose {
                        model.canvas.addPoint(pos)
                    }
                })
                .onEnded({ _ in
                    model.canvas.finishStroke()
                })
            )
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
