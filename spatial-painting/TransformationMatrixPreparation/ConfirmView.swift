//
//  ConfirmView.swift
//  multipeer-share-coordinate-throw-ball
//
//  Created by blueken on 2025/01/22.
//

import SwiftUI

struct ConfirmView: View {
    @ObservedObject var peerManager = PeerManager()
    @Binding var sharedCoordinateState: SharedCoordinateState
    
    var body: some View {
        VStack {
            Text("設定は完了しました！").font(.title)
            
            Text("座標変換行列").font(.title)
            Text(peerManager.transformationMatrix.columns.0.description)
            Text(peerManager.transformationMatrix.columns.1.description)
            Text(peerManager.transformationMatrix.columns.2.description)
            Text(peerManager.transformationMatrix.columns.3.description)
            
            Text("右手の座標の共有").font(.title)
            Text("相手").font(.title2)
            Text(peerManager.rightIndexFingerCoordinates.codable.rightIndexFingerCoordinates.description)
            
            Text("自分").font(.title2)
            Text(peerManager.myRightIndexFingerCoordinates.codable.rightIndexFingerCoordinates.description)
            
            Text("両手の座標の共有").font(.title)
            Text("相手").font(.title2)
            Text("右手").font(.title3)
            Text(peerManager.bothIndexFingerCoordinate.codable.indexFingerCoordinate.right.description)
            Text("左手").font(.title3)
            Text(peerManager.bothIndexFingerCoordinate.codable.indexFingerCoordinate.left.description)
            
            Text("自分").font(.title2)
            Text("右手").font(.title3)
            Text(peerManager.myBothIndexFingerCoordinate.codable.indexFingerCoordinate.right.description)
            Text("左手").font(.title3)
            Text(peerManager.myBothIndexFingerCoordinate.codable.indexFingerCoordinate.left.description)
            
            Button(action: {
                confirm()
            }){
                Text("設定を完了する")
            }
            .padding()
            
            Spacer()
        }
    }
    
    func confirm(){
        peerManager.transformationMatrixPreparationState = .prepared
        sharedCoordinateState = .shared
    }
}
