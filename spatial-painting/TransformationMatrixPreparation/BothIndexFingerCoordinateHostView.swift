//
//  BothIndexFingerCoordinateHostView.swift
//  multipeer-share-coordinate-throw-ball
//
//  Created by blueken on 2025/01/22.
//

import SwiftUI

struct BothIndexFingerCoordinateHostView: View {
    @ObservedObject var peerManager = PeerManager()
    @State var isCommunication = false
    
    var body: some View {
        VStack {
            Text("4. 両手の人差し指の位置を確認").font(.title)
            Divider()
            
            Text("開始ボタンを押しながら両手の人差し指で相手の両手の人差し指に触れてください")
            
            Button(action: {
                start()
            }){
                Text("開始")
            }
            .disabled(isCommunication)
            
            Spacer()
            
            if isCommunication {
                Text("両手の人差し指に触れられていましたか？").font(.title2)
                HStack{
                    Button(action: {
                        checkFingerSuccess()
                    }){
                        Text("はい")
                    }
                    Button(action: {
                        checkFingerFailure()
                    }){
                        Text("いいえ")
                    }
                }
            }
            
            Spacer()
        }
        .onChange(of: peerManager.receivedMessage){
            onChangeReceivedMessage(receivedMessage: peerManager.receivedMessage)
        }
    }
    
    func start() {
        peerManager.sendMessage("reqBothIndexFingerCoordinate")
        peerManager.isUpdatePeerManagerBothIndexFingerCoordinate = false
        Thread.sleep(forTimeInterval: 0.1)
    }
    
    func checkFingerSuccess() {
        peerManager.sendMessage("successBothIndexFingerCoordinate")
    }
    
    func checkFingerFailure() {
        peerManager.sendMessage("reset")
        isCommunication = false
    }
    
    func onChangeReceivedMessage(receivedMessage: String){
        if peerManager.receivedMessage.hasPrefix("resBothIndexFingerCoordinate") {
            receiveResBothIndexFingerCoordinate()
        } else if (peerManager.receivedMessage == "receivedSuccessBothIndexFingerCoordinate") {
            receiveReceivedSuccessBothIndexFingerCoordinate()
        }
    }
    
    func receiveResBothIndexFingerCoordinate() {
        let receivedMessage = peerManager.receivedMessage.replacingOccurrences(of: "resBothIndexFingerCoordinate", with: "")
        let data = receivedMessage.data(using: .utf8)!
        let bothIndexFingerCoordinateCodable = try! JSONDecoder().decode(BothIndexFingerCoordinateCodable.self, from: data)
        peerManager.bothIndexFingerCoordinate = BothIndexFingerCoordinate(bothIndexFingerCoordinateCodable: bothIndexFingerCoordinateCodable)
        isCommunication = true
    }
    
    func receiveReceivedSuccessBothIndexFingerCoordinate() {
        peerManager.calculateTransformationMatrix()
        print(peerManager.transformationMatrix)
        peerManager.transformationMatrixPreparationState = .confirm
    }
}
