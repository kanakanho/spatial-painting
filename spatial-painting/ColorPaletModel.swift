//
//  ColorPalet.swift
//  spatial-painting
//
//  Created by blueken on 2025/03/20.
//

import ARKit
import RealityKit
import SwiftUI

@Observable
@MainActor
class ColorPaletModel {
    var colorPaletEntity = Entity()
    
    var radius:Float = 0.08
    let material = PhysicsMaterialResource.generate(friction: 0.8,restitution: 0.0)
    
    var activeColor = SimpleMaterial.Color.white
    
    let colors:[SimpleMaterial.Color] = [
        .white,
        .black,
        .red,
        .yellow,
        .green,
        .cyan,
        .blue,
        .purple,
    ]
    
    func setActiveColor(color: SimpleMaterial.Color) {
        activeColor = color
        // 該当の色を小さくする
        for child in colorPaletEntity.children {
            if child.name == color.accessibilityName {
                child.setScale(SIMD3<Float>(0.9,0.9,0.9), relativeTo: nil)
            } else {
                child.setScale(SIMD3<Float>(1.0,1.0,1.0), relativeTo: nil)
            }
        }
    }
    
    func updatePosition(position: SIMD3<Float>) {
        for (index,color) in zip(colors.indices, colors) {
            let radians:Float = Float.pi / 180.0 * 360.0 / Float(colors.count) * Float(index)
            let ballPosition:SIMD3<Float> = position + SIMD3<Float>(radius * sin(radians),radius * cos(radians) + 0.12,0.0)
            colorPaletEntity.findEntity(named: color.accessibilityName)?.setPosition(ballPosition, relativeTo: nil)
        }
    }
    
    func initEntity() {
        for (index,color) in zip(colors.indices, colors) {
            let deg = 360.0 / Float(colors.count) * Float(index)
            let radians:Float = Float.pi / 180.0 * deg
            createColorBall(color: color, radians: radians, radius: radius, parentPosition: colorPaletEntity.position)
        }
    }
    
    func createColorBall(color: SimpleMaterial.Color,radians: Float,radius : Float,parentPosition: SIMD3<Float>) {
        let ball = ModelEntity(
            mesh: .generateSphere(radius: 0.02),
            materials: [SimpleMaterial(color: color, isMetallic: true)],
            collisionShape: .generateSphere(radius: 0.05),
            mass: 1.0
        )
        
        ball.name = color.accessibilityName
        // ball の座標を決定
        let ballPosition:SIMD3<Float> = SIMD3(radius * sin(radians),radius * cos(radians),0)
        ball.setPosition(ballPosition, relativeTo: nil)
        
        ball.components.set(InputTargetComponent(allowedInputTypes: .all))
        
        // mode が dynamic でないと物理演算が適用されない
        ball.components.set(PhysicsBodyComponent(shapes: [ShapeResource.generateSphere(radius: 0.05)], mass: 1.0, material: material, mode: .static))
        
        if (color == .white) {
            ball.setScale(SIMD3<Float>(0.9,0.9,0.9), relativeTo: nil)
        } else {
            ball.setScale(SIMD3<Float>(1.0,1.0,1.0), relativeTo: nil)
        }
        
        colorPaletEntity.addChild(ball)
    }
    
    func colorPaletEntityEnabled() {
        colorPaletEntity.isEnabled = true
    }
    
    func colorPaletEntityDisable() {
        if (colorPaletEntity.isEnabled) {
            colorPaletEntity.isEnabled = false
        }
    }
}
