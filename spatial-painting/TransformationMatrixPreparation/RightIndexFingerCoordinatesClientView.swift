//
//  RightIndexFingerCoordinatesClientView.swift
//  multipeer-share-coordinate-throw-ball
//
//  Created by blueken on 2025/01/22.
//

import SwiftUI

struct RightIndexFingerCoordinatesClientView: View {
    @ObservedObject var peerManager = PeerManager()
    
    var body: some View {
        VStack {
            Text("3. 右手の人差し指の位置を確認").font(.title)
            Divider()
            
            Text("相手が開始ボタンを押したときに、相手の右手の人差し指と自分右手の人差し指を合わせてください")
            
            Spacer()
        }
        .onChange(of: peerManager.receivedMessage){
            onChangeReceivedMessage(receivedMessage: peerManager.receivedMessage)
        }
    }
    
    // modified by nagao 2025/4/7
    func onChangeReceivedMessage(receivedMessage: String){
        if (peerManager.receivedMessage == "startRightIndexFingerCoordinates") {
            receiveStartRightIndexFingerCoordinates()
        } else if (peerManager.receivedMessage == "reqRightIndexFingerCoordinates") {
            receiveReqRightIndexFingerCoordinates()
        } else if (peerManager.receivedMessage == "successRightIndexFingerCoordinates") {
            receiveSuccessRightIndexFingerCoordinates()
        } else if (peerManager.receivedMessage == "reset"){
            receiveReset()
        }
    }
    
    func receiveStartRightIndexFingerCoordinates(){
        peerManager.myIndexFingerTrackingState = .myRightIndexFingerCoordinatesStarted
    }
    
    // modified by nagao 2025/4/7
    func receiveReqRightIndexFingerCoordinates(){
        let json = try! JSONEncoder().encode(peerManager.myRightIndexFingerCoordinates.codable)
        let jsonStr = String(data: json, encoding: .utf8) ?? ""
        peerManager.sendMessage("resRightIndexFingerCoordinates\(jsonStr)")
    }
    
    func receiveSuccessRightIndexFingerCoordinates(){
        peerManager.sendMessage("receivedSuccessRightIndexFingerCoordinates")
        peerManager.transformationMatrixPreparationState = .bothIndexFingerCoordinateClient
    }
    
    func receiveReset(){
        peerManager.isUpdatePeerManagerRightIndexFingerCoordinates = true
    }
}
