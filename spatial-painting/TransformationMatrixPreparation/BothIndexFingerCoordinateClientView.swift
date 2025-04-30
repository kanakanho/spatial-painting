//
//  BothIndexFingerCoordinateClientView.swift
//  multipeer-share-coordinate-throw-ball
//
//  Created by blueken on 2025/01/22.
//

import SwiftUI

struct BothIndexFingerCoordinateClientView: View {
    @ObservedObject var peerManager = PeerManager()
    
    var body: some View {
        VStack {
            Text("4. 両手の人差し指の位置を確認").font(.title)
            Divider()
            
            Text("相手が開始ボタンを押しながら両手の人差し指で相手の人差し指に触れてください")
            
            Spacer()
        }
        .onChange(of: peerManager.receivedMessage){
            onChangeReceivedMessage(receivedMessage: peerManager.receivedMessage)
        }
    }
    
    // modified by nagao 2025/4/7
    func onChangeReceivedMessage(receivedMessage: String){
        if (receivedMessage == "startBothIndexFingerCoordinate") {
            receiveStartBothIndexFingerCoordinate()
        } else if (receivedMessage == "reqBothIndexFingerCoordinate") {
            receiveReqBothIndexFingerCoordinate()
        } else if (receivedMessage == "successBothIndexFingerCoordinate") {
            receiveSuccessBothIndexFingerCoordinate()
        } else if (receivedMessage == "reset"){
            receiveReset()
        }
    }
    
    func receiveStartBothIndexFingerCoordinate(){
        peerManager.myIndexFingerTrackingState = .myBothIndexFingerCoordinateStarted
    }
    
    // modified by nagao 2025/4/7
    func receiveReqBothIndexFingerCoordinate(){
        let json = try! JSONEncoder().encode(peerManager.myBothIndexFingerCoordinate.codable)
        let jsonStr = String(data: json, encoding: .utf8) ?? ""
        peerManager.sendMessage("resBothIndexFingerCoordinate\(jsonStr)")
    }

    func receiveSuccessBothIndexFingerCoordinate(){
        peerManager.sendMessage("receivedSuccessBothIndexFingerCoordinate")
        peerManager.transformationMatrixPreparationState = .confirm
    }
    
    func receiveReset(){
        peerManager.isUpdatePeerManagerBothIndexFingerCoordinate = true
    }
}
