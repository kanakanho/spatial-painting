//
//  ImmersiveViewModel.swift
//  spatial-painting
//
//  Created by blueken on 2025/03/18.
//

import ARKit
import RealityKit
import SwiftUI

extension SIMD4 {
    var xyz: SIMD3<Scalar> {
        self[SIMD3(0, 1, 2)]
    }
}

@Observable
@MainActor
class ViewModel {
    let webSocketClient: WebSocketClient = .init()
    let colorPaletModel = ColorPaletModel()
    var canvas = PaintingCanvas()
    
    var isCanvasEnabled: Bool = false
    
    let session = ARKitSession()
    let handTracking = HandTrackingProvider()
    let sceneReconstruction = SceneReconstructionProvider()
    let worldTracking = WorldTrackingProvider()
    
    private var meshEntities = [UUID: ModelEntity]()
    var contentEntity = Entity()
    var latestHandTracking: HandsUpdates = .init(left: nil, right: nil)
    var leftHandEntity = Entity()
    var rightHandEntity = Entity()

    var latestRightIndexFingerCoordinates: simd_float4x4 = .init()
    var latestLeftIndexFingerCoordinates: simd_float4x4 = .init()
    
    var latestWorldTracking: WorldAnchor = .init(originFromAnchorTransform: .init())
    
    var isGlab: Bool = false
    
    enum OperationLock {
        case none
        case right
        case left
    }
    
    enum HandGlab {
        case right
        case left
    }
    
    // ここで反発係数を決定している可能性あり
    let material = PhysicsMaterialResource.generate(friction: 0.8,restitution: 0.0)
    
    struct HandsUpdates {
        var left: HandAnchor?
        var right: HandAnchor?
    }
    
    var errorState = false
    
    // ストロークを消去する時の長押し時間 added by nagao 2025/3/24
    var clearTime: Int = 0
    
    let fingerEntities: [HandAnchor.Chirality: ModelEntity] = [
        /*.left: .createFingertip(name: "L", color: UIColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 1.0)),*/
        .right: .createFingertip(name: "R", color: UIColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 1.0))
    ]
    
    func setupContentEntity() -> Entity {
        for entity in fingerEntities.values {
            contentEntity.addChild(entity)
        }
        return contentEntity
    }
    
    // 指先に球を表示 added by nagao 2025/3/22
    func showFingerTipSpheres() {
        for entity in fingerEntities.values {
            contentEntity.addChild(entity)
        }
    }
    
    func dismissFingerTipSpheres() {
        for entity in fingerEntities.values {
            entity.removeFromParent()
        }
    }
    
    func changeFingerColor(entity: Entity, colorName: String) {
        for color in colorPaletModel.colors {
            let words = color.accessibilityName.split(separator: " ")
            if let name = words.last, name == colorName {
                let material = SimpleMaterial(color: color, isMetallic: true)
                entity.components.set(ModelComponent(mesh: .generateSphere(radius: 0.01), materials: [material]))
                break
            }
        }
    }
    
    var dataProvidersAreSupported: Bool {
        HandTrackingProvider.isSupported && SceneReconstructionProvider.isSupported
    }
    
    var isReadyToRun: Bool {
        handTracking.state == .initialized && sceneReconstruction.state == .initialized
    }

    func processReconstructionUpdates() async {
        for await update in sceneReconstruction.anchorUpdates {
            let meshAnchor = update.anchor
            
            guard let shape = try? await ShapeResource.generateStaticMesh(from: meshAnchor) else { continue }
            switch update.event {
            case .added:
                let entity = ModelEntity()
                entity.transform = Transform(matrix: meshAnchor.originFromAnchorTransform)
                entity.collision = CollisionComponent(shapes: [shape], isStatic: true)
                entity.components.set(InputTargetComponent())
                
                // mode が dynamic でないと物理演算が適用されない
                entity.physicsBody = PhysicsBodyComponent(mode: .dynamic)
                
                meshEntities[meshAnchor.id] = entity
                contentEntity.addChild(entity)
            case .updated:
                guard let entity = meshEntities[meshAnchor.id] else { continue }
                entity.transform = Transform(matrix: meshAnchor.originFromAnchorTransform)
                entity.collision?.shapes = [shape]
            case .removed:
                meshEntities[meshAnchor.id]?.removeFromParent()
                meshEntities.removeValue(forKey: meshAnchor.id)
            }
        }
    }
    
    func monitorSessionEvents() async {
        for await event in session.events {
            switch event {
            case .authorizationChanged(type: _, status: let status):
                print("Authorization changed to: \(status)")
                
                if status == .denied {
                    errorState = true
                }
            case .dataProviderStateChanged(dataProviders: let providers, newState: let state, error: let error):
                print("Data provider changed: \(providers), \(state)")
                if let error {
                    print("Data provider reached an error state: \(error)")
                    errorState = true
                }
            @unknown default:
                fatalError("Unhandled new event type \(event)")
            }
        }
    }
    
    func processWorldUpdates() async {
        for await update in worldTracking.anchorUpdates {
            switch update.event {
            case .updated:
                let anchor = update.anchor
                latestWorldTracking = anchor
                print(latestWorldTracking.originFromAnchorTransform.position)
            default:
                break
            }
        }
    }
    
    func processHandUpdates() async {
        for await update in handTracking.anchorUpdates {
            switch update.event {
            case .updated:
                let anchor = update.anchor
                
                guard anchor.isTracked else { continue }
                
                // added by nagao 2025/3/22
                let fingerTipIndex = anchor.handSkeleton?.joint(.indexFingerTip)
                let originFromWrist = anchor.originFromAnchorTransform
                let wristFromIndex = fingerTipIndex?.anchorFromJointTransform
                let originFromIndex = originFromWrist * wristFromIndex!
                fingerEntities[anchor.chirality]?.setTransformMatrix(originFromIndex, relativeTo: nil)
                
                if anchor.chirality == .left {
                    latestHandTracking.left = anchor
                    guard let handAnchor = latestHandTracking.left else { continue }
                    guard let handSkeletonAnchorTransform = latestHandTracking.left?.handSkeleton?.joint(.indexFingerTip).anchorFromJointTransform else { return }
                    latestLeftIndexFingerCoordinates = handAnchor.originFromAnchorTransform * handSkeletonAnchorTransform
                    watchLeftPalm(handAnchor: handAnchor)
                    // webSocketClient.sendHandAnchor(handAnchor)
                } else if anchor.chirality == .right {
                    latestHandTracking.right = anchor
                    guard let handAnchor = latestHandTracking.right else { continue }
                    guard let handSkeletonAnchorTransform = latestHandTracking.right?.handSkeleton?.joint(.indexFingerTip).anchorFromJointTransform else { return }
                    latestRightIndexFingerCoordinates = handAnchor.originFromAnchorTransform * handSkeletonAnchorTransform
                }
            default:
                break
            }
        }
    }

    // 手のひらをどこに向けているのかを判定
    func watchLeftPalm(handAnchor: HandAnchor) {
        // 座標変換の処理が終了するまでは、お絵描きの機能を行えないようにする
        if !isCanvasEnabled {
            return
        }
        
        guard let middleFingerIntermediateBase = handAnchor.handSkeleton?.joint(.middleFingerIntermediateBase) else {
            return
        }
        
        let positionMatrix: simd_float4x4 = handAnchor.originFromAnchorTransform * middleFingerIntermediateBase.anchorFromJointTransform
        
        if (positionMatrix.codable[1][1] < positionMatrix.codable[2][2]) {
            colorPaletModel.colorPaletEntityDisable()
            return
        }
        
        colorPaletModel.colorPaletEntityEnabled()
        
        guard let wristBase = handAnchor.handSkeleton?.joint(.wrist) else {
            return
        }
        
        let wristMatrix: simd_float4x4 = handAnchor.originFromAnchorTransform * wristBase.anchorFromJointTransform
        
        colorPaletModel.updatePosition(position: positionMatrix.position, wristPosition: wristMatrix.position)
    }
    
    // 色を選択する added by nagao 2025/3/22
    func selectColor(colorName: String) {
        for color in colorPaletModel.colors {
            let words = color.accessibilityName.split(separator: " ")
            if let name = words.last, name == colorName {
                //print("💥 Selected color accessibilityName \(color.accessibilityName)")
                colorPaletModel.colorPaletEntityDisable()
                colorPaletModel.setActiveColor(color: color)
                canvas.setActiveColor(color: color)
                //canvas.currentStroke?.setActiveColor(color: color)
                break
            }
        }
    }
    
    // ストロークを消去する時の長押し時間の処理 added by nagao 2025/3/24
    func recordTime(isBegan: Bool) -> Bool {
        if isBegan {
            let now = Date()
            let milliseconds = Int(now.timeIntervalSince1970 * 1000)
            let calendar = Calendar.current
            let nanoseconds = calendar.component(.nanosecond, from: now)
            let exactMilliseconds = milliseconds + (nanoseconds / 1_000_000)
            clearTime = exactMilliseconds
            //print("現在時刻: \(exactMilliseconds)")
            return true
        } else {
            if clearTime > 0 {
                let now = Date()
                let milliseconds = Int(now.timeIntervalSince1970 * 1000)
                let calendar = Calendar.current
                let nanoseconds = calendar.component(.nanosecond, from: now)
                let exactMilliseconds = milliseconds + (nanoseconds / 1_000_000)
                let time = exactMilliseconds - clearTime
                if time > 1000 {
                    clearTime = 0
                    //print("経過時間: \(time)")
                    return true
                }
            }
            return false
        }
    }
    
    func initBall(position: SIMD3<Float>) {
        let ball = ModelEntity(
            mesh: .generateSphere(radius: 0.05),
            materials: [SimpleMaterial(color: .red, isMetallic: true)],
            collisionShape: .generateSphere(radius: 0.05),
            mass: 0.0
        )
        ball.name = "rightIndexTip"
        ball.setPosition(position, relativeTo: nil)
        ball.components.set(InputTargetComponent(allowedInputTypes: .all))
        
        contentEntity.addChild(ball)
    }
}
