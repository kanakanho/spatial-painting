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
                content.add(root)

                // added by nagao 2025/3/22
                for fingerEntity in model.fingerEntities.values {
                    //print("Collision Setting for \(fingerEntity.name)")
                    _ = content.subscribe(to: CollisionEvents.Began.self, on: fingerEntity) { collisionEvent in
                        // 座標変換の処理が終了するまでは、お絵描きの機能を行えないようにする
                        if peerManager.transformationMatrixPreparationState != .prepared {
                            return
                        }

                        if model.colorPaletModel.colorNames.contains(collisionEvent.entityB.name) {
                            model.changeFingerColor(entity: fingerEntity, colorName: collisionEvent.entityB.name)
                            //print("💥 Collision between \(collisionEvent.entityA.name) and \(collisionEvent.entityB.name) began")
                        } else if (collisionEvent.entityB.name == "clear") {
                            _ = model.recordTime(isBegan: true)
                        }
                    }

                    _ = content.subscribe(to: CollisionEvents.Ended.self, on: fingerEntity) { collisionEvent in
                        // 座標変換の処理が終了するまでは、お絵描きの機能を行えないようにする
                        if peerManager.transformationMatrixPreparationState != .prepared {
                            return
                        }
                        
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
                    // 座標変換の処理が終了するまでは、お絵描きの機能を行えないようにする
                    if peerManager.transformationMatrixPreparationState != .prepared {
                        return
                    }

                    if let pos = lastIndexPose {
                        model.canvas.addPoint(pos)
//                        if (peerManager.isHost){
//                            let matrix:[Double] = [pos.x.toDouble(), pos.y.toDouble(), pos.z.toDouble(), 1]
//                            let clientPos = matmul4x4_4x1(peerManager.transformationMatrixClientToHost.toDoubleList(),matrix)
//                            peerManager.sendMessage("addPoint:\(clientPos[0].toFloat()),\(clientPos[1].toFloat()),\(clientPos[2].toFloat())")
//                        } else {
//                            peerManager.sendMessage("addPoint:\(pos.x),\(pos.y),\(pos.z)")
//                        }
                        let matrix:[Double] = [pos.x.toDouble(), pos.y.toDouble(), pos.z.toDouble(), 1]
                        let clientPos = matmul4x4_4x1(peerManager.transformationMatrix.toDoubleList(),matrix)
                        peerManager.sendMessage("addPoint:\(clientPos[0].toFloat()),\(clientPos[1].toFloat()),\(clientPos[2].toFloat())")
                    }
                })
                .onEnded({ _ in
                    // 座標変換の処理が終了するまでは、お絵描きの機能を行えないようにする
                    if peerManager.transformationMatrixPreparationState != .prepared {
                        return
                    }

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
        // added by nagao 2025/4/7
        .onChange(of: peerManager.myIndexFingerTrackingState) {
            respondToStateChange()
        }
        .onChange(of: peerManager.receivedMessage) {
            if (peerManager.receivedMessage.hasPrefix("selectColor:")){
                let receivedMessage = peerManager.receivedMessage.replacingOccurrences(of: "selectColor:", with: "")
                model.selectColor(colorName: receivedMessage)
            } else if (peerManager.receivedMessage.hasPrefix("addPoint:")){
                let receivedMessage = peerManager.receivedMessage.replacingOccurrences(of: "addPoint:", with: "")
                let point = receivedMessage.split(separator: ",").map { Float($0) ?? 0 }
//                if (peerManager.isHost) {
//                    let matrix:[Double] = [point[0].toDouble(), point[1].toDouble(), point[2].toDouble(), 1]
//                    let clientPos = matmul4x4_4x1(peerManager.transformationMatrixClientToHost.toDoubleList(),matrix)
//                    let pos = SIMD3<Float>(clientPos[0].toFloat(), clientPos[1].toFloat(), clientPos[2].toFloat())
//                    model.canvas.addPoint(pos)
//                } else {
//                    let pos = SIMD3<Float>(point[0], point[1], point[2])
//                    model.canvas.addPoint(pos)
//                }
                let pos = SIMD3<Float>(point[0], point[1], point[2])
                model.canvas.addPoint(pos)
            } else if (peerManager.receivedMessage == "finishStroke"){
                model.canvas.finishStroke()
            } else if (peerManager.receivedMessage.hasPrefix("reqPrepareInitBall")) {
                // 受け取った相手の右手の行列を相手側に表示させるための行列に加工
                let receivedMessage = peerManager.receivedMessage.replacingOccurrences(of: "reqPrepareInitBall", with: "")
                // デコード
                let data = receivedMessage.data(using: .utf8)!
                let rightIndexMatrix = try! JSONDecoder().decode([[Float]].self, from: data)
                // 計算
                let anotherTransform =  peerManager.transformationMatrix * rightIndexMatrix.tosimd_float4x4()
                // エンコード
                let json = try! JSONEncoder().encode(anotherTransform.codable)
                let jsonStr = String(data: json, encoding: .utf8) ?? ""
                peerManager.sendMessage("reqInitBall\(jsonStr)")
            } else if (peerManager.receivedMessage.hasPrefix("reqInitBall")) {
                // 受け取った行列をそのまま表示に用いる
                let receivedMessage = peerManager.receivedMessage.replacingOccurrences(of: "reqPrepareInitBall", with: "")
                let data = receivedMessage.data(using: .utf8)!
                let ballMatrix = try! JSONDecoder().decode([[Float]].self, from: data)
                model.initBall(transform: ballMatrix.tosimd_float4x4())
            }
//            if (peerManager.receivedMessage.hasPrefix("matrix:")){
//                let receivedMessage = peerManager.receivedMessage.replacingOccurrences(of: "matrix:", with: "")
//                receiveMatrix(message: receivedMessage)
//            }
        }
        .onChange(of: peerManager.transformationMatrixPreparationState) {
            if (peerManager.transformationMatrixPreparationState == .prepared) {
                model.isCanvasEnabled = true
                let json = try! JSONEncoder().encode(peerManager.myRightIndexFingerCoordinates.rightIndexFingerCoordinates.codable)
                let jsonStr = String(data: json, encoding: .utf8) ?? ""
                peerManager.sendMessage("reqPrepareInitBall\(jsonStr)")
//                if (peerManager.isHost) {
//                    model.initBall(transform: peerManager.transformationMatrixClientToHost * peerManager.rightIndexFingerCoordinates.rightIndexFingerCoordinates)
//                } else {
//                    model.initBall(transform: peerManager.myRightIndexFingerCoordinates.rightIndexFingerCoordinates)
//                }
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
    
    // added by nagao 2025/4/7
    func respondToStateChange() {
        if (peerManager.myIndexFingerTrackingState == .initial) {
            model.showFingerTipSpheres()
        } else if (peerManager.myIndexFingerTrackingState == .myRightIndexFingerCoordinatesStarted) {
            model.fingerSignal(hand: .right, flag: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                Task {
                    peerManager.isUpdatePeerManagerRightIndexFingerCoordinates = false
                    if peerManager.isHost {
                        peerManager.sendMessage("reqRightIndexFingerCoordinates")
                    }
                    model.fingerSignal(hand: .right, flag: false)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        Task {
                            if peerManager.isHost {
                                peerManager.sendMessage("successRightIndexFingerCoordinates")
                            }
                        }
                    }
                }
            }
        } else if (peerManager.myIndexFingerTrackingState == .myBothIndexFingerCoordinateStarted) {
            model.fingerSignal(hand: .right, flag: true)
            //model.fingerSignal(hand: .left, flag: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                Task {
                    peerManager.isUpdatePeerManagerBothIndexFingerCoordinate = false
                    if peerManager.isHost {
                        peerManager.sendMessage("reqBothIndexFingerCoordinate")
                    }
                    model.fingerSignal(hand: .right, flag: false)
                    //model.fingerSignal(hand: .left, flag: false)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        Task {
                            if peerManager.isHost {
                                peerManager.sendMessage("successBothIndexFingerCoordinate")
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView(peerManager: PeerManager())
        .environment(AppModel())
}
