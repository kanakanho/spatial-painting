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
    @ObservedObject var peerManager : PeerManager

    @State var latestRightIndexFingerCoordinates: simd_float4x4 = .init()
    @State var latestLeftIndexFingerCoordinates: simd_float4x4 = .init()
    
    
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
                let anotherUserRoot = model.anotherUserCanvas.root
                content.add(root)
                content.add(anotherUserRoot)

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
                            peerManager.sendMessage("selectColor:\(collisionEvent.entityB.name)")
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
                        if (peerManager.isHost){
                            let matrix = simd_float4x4(
                                SIMD4<Float>(1, 0, 0, 0),
                                SIMD4<Float>(0, 1, 0, 0),
                                SIMD4<Float>(0, 0, 1, 0),
                                SIMD4<Float>(pos.x, pos.y, pos.z, 1)
                            )
                            let clientMatrix = matrix * peerManager.transformationMatrix
                            let clinetPos = clientMatrix.position
                            peerManager.sendMessage("addPoint:\(clinetPos.x),\(clinetPos.y),\(clinetPos.z)")
                        } else {
                            peerManager.sendMessage("addPoint:\(pos.x),\(pos.y),\(pos.z)")
                        }
                    }
                })
                .onEnded({ _ in
                    model.canvas.finishStroke()
                    peerManager.sendMessage("finishStroke")
                })
            )
        .onChange(of: model.errorState) {
            openWindow(id: "error")
        }
        .onChange(of: model.latestRightIndexFingerCoordinates) {
            if (!peerManager.isUpdatePeerManagerBothIndexFingerCoordinate){
                return
            }
            
            latestRightIndexFingerCoordinates = model.latestRightIndexFingerCoordinates
            
            peerManager.myBothIndexFingerCoordinate = BothIndexFingerCoordinate(unixTime: Int(Date().timeIntervalSince1970), indexFingerCoordinate: IndexFingerCoordinate(left:  latestLeftIndexFingerCoordinates, right:  latestRightIndexFingerCoordinates))
            
            if (!peerManager.isUpdatePeerManagerRightIndexFingerCoordinates){
                return
            }
            
            peerManager.myRightIndexFingerCoordinates = RightIndexFingerCoordinates(unixTime: Int(Date().timeIntervalSince1970), rightIndexFingerCoordinates:  latestRightIndexFingerCoordinates)
        }
        .onChange(of: model.latestLeftIndexFingerCoordinates) {
            if (!peerManager.isUpdatePeerManagerBothIndexFingerCoordinate){
                return
            }
            latestLeftIndexFingerCoordinates = model.latestLeftIndexFingerCoordinates
            
            peerManager.myBothIndexFingerCoordinate = BothIndexFingerCoordinate(unixTime: Int(Date().timeIntervalSince1970), indexFingerCoordinate: IndexFingerCoordinate(left: latestLeftIndexFingerCoordinates, right:  latestRightIndexFingerCoordinates))
        }
        .onChange(of: peerManager.receivedMessage) {
            if (peerManager.receivedMessage.hasPrefix("selectColor:")){
                let receivedMessage = peerManager.receivedMessage.replacingOccurrences(of: "selectColor:", with: "")
                model.selectColor(colorName: receivedMessage)
            } else if (peerManager.receivedMessage.hasPrefix("addPoint:")){
                let receivedMessage = peerManager.receivedMessage.replacingOccurrences(of: "addPoint:", with: "")
                let point = receivedMessage.split(separator: ",").map { Float($0) ?? 0 }
                if (peerManager.isHost) {
                    let matrix = simd_float4x4(
                        SIMD4<Float>(1, 0, 0, 0),
                        SIMD4<Float>(0, 1, 0, 0),
                        SIMD4<Float>(0, 0, 1, 0),
                        SIMD4<Float>(point[0], point[1], point[2], 1)
                    )
                    let clientMatrix = matrix * peerManager.transformationMatrixClientToHost
                    let clinetPos = clientMatrix.position
                    let originPoints:[SIMD3<Float>] = [
                        peerManager.myRightIndexFingerCoordinates.rightIndexFingerCoordinates.position,
                        peerManager.myBothIndexFingerCoordinate.indexFingerCoordinate.left.position,
                        peerManager.myBothIndexFingerCoordinate.indexFingerCoordinate.right.position
                    ]
                    let originPoint:SIMD3<Float> = SIMD3<Float>(
                        (originPoints[0].x + originPoints[1].x + originPoints[2].x) / 3,
                        (originPoints[0].y + originPoints[1].y + originPoints[2].y) / 3,
                        0
                    )
                    let offset = originPoint - SIMD3<Float>(clinetPos[0], clinetPos[1], clinetPos[2])
                    model.anotherUserCanvas.addPoint(SIMD3<Float>(offset.x,offset.y,clinetPos.z))
                } else {
                    let originPoints:[SIMD3<Float>] = [
                        peerManager.myRightIndexFingerCoordinates.rightIndexFingerCoordinates.position,
                        peerManager.myBothIndexFingerCoordinate.indexFingerCoordinate.left.position,
                        peerManager.myBothIndexFingerCoordinate.indexFingerCoordinate.right.position
                    ]
                    let originPoint:SIMD3<Float> = SIMD3<Float>(
                        (originPoints[0].x + originPoints[1].x + originPoints[2].x) / 3,
                        (originPoints[0].y + originPoints[1].y + originPoints[2].y) / 3,
                        0
                    )
                    let offset = originPoint - SIMD3<Float>(point[0], point[1], point[2])
                    model.anotherUserCanvas.addPoint(SIMD3<Float>(offset.x,offset.y,point[2]))
                }
            } else if (peerManager.receivedMessage == "finishStroke"){
                model.anotherUserCanvas.finishStroke()
            }
//            if (peerManager.receivedMessage.hasPrefix("matrix:")){
//                let receivedMessage = peerManager.receivedMessage.replacingOccurrences(of: "matrix:", with: "")
//                receiveMatrix(message: receivedMessage)
//            }
        }
        .onChange(of: peerManager.transformationMatrixPreparationState) {
            if (peerManager.transformationMatrixPreparationState == .prepared) {
            }
        }
    }

    func sendMatrix() {
        model.contentEntity.children.forEach { entity in
            let clientTransformMatrix =  entity.transform.matrix * peerManager.transformationMatrix
            let floatList: [Float] = clientTransformMatrix.floatList
            let floatListStr = floatList.map { String($0) }
            peerManager.sendMessage("matrix:\(entity.name),\(floatListStr)")
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView(peerManager: PeerManager())
        .environment(AppModel())
}
