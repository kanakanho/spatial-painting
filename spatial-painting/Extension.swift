//
//  Extension.swift
//  multipeer-share-coordinate-throw-ball
//
//  Created by blueken on 2024/12/27.
//

import ARKit

extension simd_float3 {
    var list: [Float] {
        return [x, y, z]
    }
}

extension simd_float4x4 {
    var position: SIMD3<Float> {
        self.columns.3.xyz
    }
    
    init?(floatListStr: [String]) {
        let values = floatListStr.compactMap(Float.init)
        if values.count != 16 { return nil }
        
        self.init([
            SIMD4<Float>(values[0], values[1], values[2], values[3]),
            SIMD4<Float>(values[4], values[5], values[6], values[7]),
            SIMD4<Float>(values[8], values[9], values[10], values[11]),
            SIMD4<Float>(values[12], values[13], values[14], values[15])
        ])
    }
    
    var floatList: [Float] {
        return [
            self.columns.0.x, self.columns.0.y, self.columns.0.z, self.columns.0.w,
            self.columns.1.x, self.columns.1.y, self.columns.1.z, self.columns.1.w,
            self.columns.2.x, self.columns.2.y, self.columns.2.z, self.columns.2.w,
            self.columns.3.x, self.columns.3.y, self.columns.3.z, self.columns.3.w
        ]
     }
    
    func toDoubleList() -> [[Double]] {
        return [
            [Double(self.columns.0.x), Double(self.columns.0.y), Double(self.columns.0.z), Double(self.columns.0.w)],
            [Double(self.columns.1.x), Double(self.columns.1.y), Double(self.columns.1.z), Double(self.columns.1.w)],
            [Double(self.columns.2.x), Double(self.columns.2.y), Double(self.columns.2.z), Double(self.columns.2.w)],
            [Double(self.columns.3.x), Double(self.columns.3.y), Double(self.columns.3.z), Double(self.columns.3.w)]
        ]
    }
}

extension Float {
    func toDouble() -> Double {
        Double(self)
    }
}

extension Double {
    func toFloat() -> Float {
        Float(self)
    }
}

extension [[Double]] {
    var transpose4x4: [[Double]] {
        var result = [[Double]](repeating: [Double](repeating: 0, count: 4), count: 4)
        for i in 0..<4 {
            for j in 0..<4 {
                result[i][j] = self[j][i]
            }
        }
        return result
    }
    
    func tosimd_float4x4() -> simd_float4x4 {
        return simd_float4x4([
            SIMD4<Float>(self[0][0].toFloat(), self[0][1].toFloat(), self[0][2].toFloat(), self[0][3].toFloat()),
            SIMD4<Float>(self[1][0].toFloat(), self[1][1].toFloat(), self[1][2].toFloat(), self[1][3].toFloat()),
            SIMD4<Float>(self[2][0].toFloat(), self[2][1].toFloat(), self[2][2].toFloat(), self[2][3].toFloat()),
            SIMD4<Float>(self[3][0].toFloat(), self[3][1].toFloat(), self[3][2].toFloat(), self[3][3].toFloat())
        ])
    }
}

