//
//  InitialView.swift
//  multipeer-share-coordinate-throw-ball
//
//  Created by blueken on 2025/01/22.
//

import SwiftUI

struct InitialView: View {
    @ObservedObject var peerManager = PeerManager()

    var body: some View {
        VStack {
            if peerManager.peerID != nil {
                Button(action: {
                    firstSendMessage()
                }){
                    Text("初期設定を開始します")
                }
            } else {
                Text("端末のIDが認識できません")
            }
        }
    }
    
    func firstSendMessage() {
        peerManager.firstSendMessage()
        peerManager.transformationMatrixPreparationState = .searching
    }
}
