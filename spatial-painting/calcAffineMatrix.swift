//
//  CalculateTransformationMatrix.swift
//  multipeer-share-coordinate-throw-ball
//
//  Created by blueken on 2025/02/07.
//

func matrixMul4x4(_ A: [[Double]], _ B: [[Double]]) -> [[Double]] {
    var result = [[Double]](repeating: [Double](repeating: 0, count: 4), count: 4)
    for i in 0..<4 {
        for j in 0..<4 {
            for k in 0..<4 {
                result[i][j] += A[i][k] * B[k][j]
            }
        }
    }
    return result
}

func LU(_ A: [[Double]]) -> ([[Double]], [[Double]]) {
    var L = [[Double]](repeating: [Double](repeating: 0, count: 4), count: 4)
    var U = [[Double]](repeating: [Double](repeating: 0, count: 4), count: 4)

    for i in 0..<4 {
        L[i][i] = 1  // 対角成分は1

        for j in i..<4 {
            var sum: Double = 0.0
            for k in 0..<i {
                sum += L[i][k] * U[k][j]
            }
            U[i][j] = A[i][j] - sum
        }

        for j in (i+1)..<4 {
            var sum: Double = 0.0
            for k in 0..<i {
                sum += L[j][k] * U[k][i]
            }
            L[j][i] = (A[j][i] - sum) / (U[i][i])
        }
    }

    return (L, U)
}

func eqSolve(_ A: [[Double]], _ Q: [[Double]]) -> [[Double]] {
    var (L, U) = LU(A)
    var Y = [[Double]](repeating: [Double](repeating: 0, count: 4), count: 4)
    var X = [[Double]](repeating: [Double](repeating: 0, count: 4), count: 4)

    // 前進代入 L * Y = Q
    for i in 0..<4 {
        var dot = [Double](repeating: 0, count: 4)
        for j in 0..<i {
            for k in 0..<4 {
                dot[k] += L[i][j] * Y[j][k]
            }
        }

        for k in 0..<4 {
            Y[i][k] = Q[i][k] - dot[k]
        }
    }

    // 後退代入 U * X = Y
    for i in stride(from: 3, through: 0, by: -1) {
        if abs(U[i][i]) < 1e-8 {  // 0除算防止
            print("Warning: U[\(i), \(i)] is nearly zero. Adding small value.")
            U[i][i] = 1e-8
        }
        var dot:[Double] = [0, 0, 0]
        for j in stride(from: 3, through: i+1, by: -1) {
            for k in 0..<3 {
                dot[k] += U[i][j] * X[j][k]
            }
        }
        for k in 0..<3 {
            X[i][k] = (Y[i][k] - dot[k]) / U[i][i]
        }
    }

    return X
}

/*
 let A:[[[Double]]] = [
        [[1, 0, 0, 7],[0, 1, 0, 9],[0, 0, 1, 8],[0, 0, 0, 1]],
        [[1, 0, 0, 7],[0, 1, 0, 7],[0, 0, 1, 8],[0, 0, 0, 1]],
        [[1, 0, 0, 23],[0, 1, 0, 25],[0, 0, 1, 23],[0, 0, 0, 1]],
    ]
 
 let B:[[[Double]]] = [
        [[1, 0, 0, 13],[0, 1, 0, 15],[0, 0, 1, 14],[0, 0, 0, 1]],
        [[1, 0, 0, 15],[0, 1, 0, 15],[0, 0, 1, 16],[0, 0, 0, 1]],
        [[1, 0, 0, 33],[0, 1, 0, 35],[0, 0, 1, 33],[0, 0, 0, 1]],
    ]
 
 calcAffineMatrix(A, B)
 */
func calcAffineMatrix(_ A: [[[Double]]], _ B: [[[Double]]]) -> [[Double]] {    
    var P:[[Double]] = []
    for i in (0..<3) {
        var rowP:[Double] = []
        for j in (0..<3) {
            rowP.append(A[i][j][3])
        }
        rowP.append(1.0)
        P.append(rowP)
    }
    P.append([0, 0, 0, 0])

    var Q:[[Double]] = []
    for i in (0..<3) {
        var rowQ:[Double] = []
        for j in (0..<3) {
            rowQ.append(B[i][j][3])
        }
        rowQ.append(0.0)
        Q.append(rowQ)
    }
    Q.append([0, 0, 0, 0])

    let eqSolveMatrix:[[Double]] = matrixMul4x4(eqSolve(matrixMul4x4(P.transpose4x4, P), P.transpose4x4), Q)
    var affineMatrix:[[Double]] = eqSolveMatrix.transpose4x4
    affineMatrix[3][3] = 1.0

    return affineMatrix
}
