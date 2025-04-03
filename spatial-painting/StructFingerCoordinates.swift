//
//  StructFingerCoordinates.swift
//  multipeer-share-coordinate-throw-ball
//
//  Created by blueken on 2025/01/23.
//

import ARKit

/*
 [[Float]]の中身
 [matrix.columns.0.x, matrix.columns.0.y, matrix.columns.0.z, matrix.columns.0.w],
 [matrix.columns.1.x, matrix.columns.1.y, matrix.columns.1.z, matrix.columns.1.w],
 [matrix.columns.2.x, matrix.columns.2.y, matrix.columns.2.z, matrix.columns.2.w],
 [matrix.columns.3.x, matrix.columns.3.y, matrix.columns.3.z, matrix.columns.3.w]
 */

struct RightIndexFingerCoordinatesCodable: Codable {
    var unixTime: Int
    var rightIndexFingerCoordinates: [[Float]]
}

struct RightIndexFingerCoordinates {
    var unixTime: Int
    var rightIndexFingerCoordinates: simd_float4x4
    
    init(unixTime: Int, rightIndexFingerCoordinates: simd_float4x4) {
        self.unixTime = unixTime
        self.rightIndexFingerCoordinates = rightIndexFingerCoordinates
    }
    
    init(rightIndexFingerCoordinatesCodable: RightIndexFingerCoordinatesCodable) {
        self.unixTime = rightIndexFingerCoordinatesCodable.unixTime
        self.rightIndexFingerCoordinates = simd_float4x4([
            simd_float4(rightIndexFingerCoordinatesCodable.rightIndexFingerCoordinates[0][0], rightIndexFingerCoordinatesCodable.rightIndexFingerCoordinates[0][1], rightIndexFingerCoordinatesCodable.rightIndexFingerCoordinates[0][2], rightIndexFingerCoordinatesCodable.rightIndexFingerCoordinates[0][3]),
            simd_float4(rightIndexFingerCoordinatesCodable.rightIndexFingerCoordinates[1][0], rightIndexFingerCoordinatesCodable.rightIndexFingerCoordinates[1][1], rightIndexFingerCoordinatesCodable.rightIndexFingerCoordinates[1][2], rightIndexFingerCoordinatesCodable.rightIndexFingerCoordinates[1][3]),
            simd_float4(rightIndexFingerCoordinatesCodable.rightIndexFingerCoordinates[2][0], rightIndexFingerCoordinatesCodable.rightIndexFingerCoordinates[2][1], rightIndexFingerCoordinatesCodable.rightIndexFingerCoordinates[2][2], rightIndexFingerCoordinatesCodable.rightIndexFingerCoordinates[2][3]),
            simd_float4(rightIndexFingerCoordinatesCodable.rightIndexFingerCoordinates[3][0], rightIndexFingerCoordinatesCodable.rightIndexFingerCoordinates[3][1], rightIndexFingerCoordinatesCodable.rightIndexFingerCoordinates[3][2], rightIndexFingerCoordinatesCodable.rightIndexFingerCoordinates[3][3])
        ])
    }
    
    var codable: RightIndexFingerCoordinatesCodable {
        return RightIndexFingerCoordinatesCodable(unixTime: unixTime, rightIndexFingerCoordinates: [
            [rightIndexFingerCoordinates.columns.0.x, rightIndexFingerCoordinates.columns.0.y, rightIndexFingerCoordinates.columns.0.z, rightIndexFingerCoordinates.columns.0.w],
            [rightIndexFingerCoordinates.columns.1.x, rightIndexFingerCoordinates.columns.1.y, rightIndexFingerCoordinates.columns.1.z, rightIndexFingerCoordinates.columns.1.w],
            [rightIndexFingerCoordinates.columns.2.x, rightIndexFingerCoordinates.columns.2.y, rightIndexFingerCoordinates.columns.2.z, rightIndexFingerCoordinates.columns.2.w],
            [rightIndexFingerCoordinates.columns.3.x, rightIndexFingerCoordinates.columns.3.y, rightIndexFingerCoordinates.columns.3.z, rightIndexFingerCoordinates.columns.3.w]
        ])
    }
}

struct IndexFingerCoordinateCodable: Codable {
    var left: [[Float]]
    var right: [[Float]]
}

struct IndexFingerCoordinate {
    var left: simd_float4x4
    var right: simd_float4x4
}

struct BothIndexFingerCoordinateCodable: Codable {
    var unixTime: Int
    var indexFingerCoordinate: IndexFingerCoordinateCodable
}

struct BothIndexFingerCoordinate {
    var unixTime: Int
    var indexFingerCoordinate: IndexFingerCoordinate
    
    init(unixTime: Int, indexFingerCoordinate: IndexFingerCoordinate) {
        self.unixTime = unixTime
        self.indexFingerCoordinate = indexFingerCoordinate
    }
    
    init(bothIndexFingerCoordinateCodable: BothIndexFingerCoordinateCodable) {
        self.unixTime = bothIndexFingerCoordinateCodable.unixTime
        self.indexFingerCoordinate = IndexFingerCoordinate(left: simd_float4x4([
            simd_float4(bothIndexFingerCoordinateCodable.indexFingerCoordinate.left[0][0], bothIndexFingerCoordinateCodable.indexFingerCoordinate.left[0][1], bothIndexFingerCoordinateCodable.indexFingerCoordinate.left[0][2], bothIndexFingerCoordinateCodable.indexFingerCoordinate.left[0][3]),
            simd_float4(bothIndexFingerCoordinateCodable.indexFingerCoordinate.left[1][0], bothIndexFingerCoordinateCodable.indexFingerCoordinate.left[1][1], bothIndexFingerCoordinateCodable.indexFingerCoordinate.left[1][2], bothIndexFingerCoordinateCodable.indexFingerCoordinate.left[1][3]),
            simd_float4(bothIndexFingerCoordinateCodable.indexFingerCoordinate.left[2][0], bothIndexFingerCoordinateCodable.indexFingerCoordinate.left[2][1], bothIndexFingerCoordinateCodable.indexFingerCoordinate.left[2][2], bothIndexFingerCoordinateCodable.indexFingerCoordinate.left[2][3]),
            simd_float4(bothIndexFingerCoordinateCodable.indexFingerCoordinate.left[3][0], bothIndexFingerCoordinateCodable.indexFingerCoordinate.left[3][1], bothIndexFingerCoordinateCodable.indexFingerCoordinate.left[3][2], bothIndexFingerCoordinateCodable.indexFingerCoordinate.left[3][3])
        ]), right: simd_float4x4([
            simd_float4(bothIndexFingerCoordinateCodable.indexFingerCoordinate.right[0][0], bothIndexFingerCoordinateCodable.indexFingerCoordinate.right[0][1], bothIndexFingerCoordinateCodable.indexFingerCoordinate.right[0][2], bothIndexFingerCoordinateCodable.indexFingerCoordinate.right[0][3]),
            simd_float4(bothIndexFingerCoordinateCodable.indexFingerCoordinate.right[1][0], bothIndexFingerCoordinateCodable.indexFingerCoordinate.right[1][1], bothIndexFingerCoordinateCodable.indexFingerCoordinate.right[1][2], bothIndexFingerCoordinateCodable.indexFingerCoordinate.right[1][3]),
            simd_float4(bothIndexFingerCoordinateCodable.indexFingerCoordinate.right[2][0], bothIndexFingerCoordinateCodable.indexFingerCoordinate.right[2][1], bothIndexFingerCoordinateCodable.indexFingerCoordinate.right[2][2], bothIndexFingerCoordinateCodable.indexFingerCoordinate.right[2][3]),
            simd_float4(bothIndexFingerCoordinateCodable.indexFingerCoordinate.right[3][0], bothIndexFingerCoordinateCodable.indexFingerCoordinate.right[3][1], bothIndexFingerCoordinateCodable.indexFingerCoordinate.right[3][2], bothIndexFingerCoordinateCodable.indexFingerCoordinate.right[3][3])
        ]))}
    
    var codable: BothIndexFingerCoordinateCodable {
        return BothIndexFingerCoordinateCodable(unixTime: unixTime, indexFingerCoordinate: IndexFingerCoordinateCodable(left: [
            [indexFingerCoordinate.left.columns.0.x, indexFingerCoordinate.left.columns.0.y, indexFingerCoordinate.left.columns.0.z, indexFingerCoordinate.left.columns.0.w],
            [indexFingerCoordinate.left.columns.1.x, indexFingerCoordinate.left.columns.1.y, indexFingerCoordinate.left.columns.1.z, indexFingerCoordinate.left.columns.1.w],
            [indexFingerCoordinate.left.columns.2.x, indexFingerCoordinate.left.columns.2.y, indexFingerCoordinate.left.columns.2.z, indexFingerCoordinate.left.columns.2.w],
            [indexFingerCoordinate.left.columns.3.x, indexFingerCoordinate.left.columns.3.y, indexFingerCoordinate.left.columns.3.z, indexFingerCoordinate.left.columns.3.w]
        ], right: [
            [indexFingerCoordinate.right.columns.0.x, indexFingerCoordinate.right.columns.0.y, indexFingerCoordinate.right.columns.0.z, indexFingerCoordinate.right.columns.0.w],
            [indexFingerCoordinate.right.columns.1.x, indexFingerCoordinate.right.columns.1.y, indexFingerCoordinate.right.columns.1.z, indexFingerCoordinate.right.columns.1.w],
            [indexFingerCoordinate.right.columns.2.x, indexFingerCoordinate.right.columns.2.y, indexFingerCoordinate.right.columns.2.z, indexFingerCoordinate.right.columns.2.w],
            [indexFingerCoordinate.right.columns.3.x, indexFingerCoordinate.right.columns.3.y, indexFingerCoordinate.right.columns.3.z, indexFingerCoordinate.right.columns.3.w]
        ]))
    }
}
