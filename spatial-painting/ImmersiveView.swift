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

    @State var canvas = PaintingCanvas()
    @State var lastIndexPose: SIMD3<Float>?

    var body: some View {
        RealityView { content in
            content.add(model.setupContentEntity())
            let root = canvas.root
            content.add(root)
            
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
                    let pinchThreshold: Float = 0.05

                    // Update the last index position if the distance
                    // between the thumb tip and index finger tip is
                    // less than the pinch threshold.
                    if length(thumbPos - indexPos) < pinchThreshold {
                        lastIndexPose = indexPos
                    }
                }
            }))
        }
        .task {
            do {
                if model.dataProvidersAreSupported && model.isReadyToRun {
                    try await model.session.run([model.sceneReconstruction, model.handTracking])
                } else {
                    await dismissImmersiveSpace()
                }
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
        .gesture(
            DragGesture(minimumDistance: 0)
                .targetedToAnyEntity()
                .onChanged({ _ in
                    if let pos = lastIndexPose {
                        canvas.addPoint(pos)
                    }
                })
                .onEnded({ _ in
                    canvas.finishStroke()
                })
            )
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
