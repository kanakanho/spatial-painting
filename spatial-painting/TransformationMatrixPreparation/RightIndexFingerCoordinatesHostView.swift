//
//  RightIndexFingerCoordinatesHostView.swift
//  multipeer-share-coordinate-throw-ball
//
//  Created by blueken on 2025/01/22.
//

import SwiftUI

struct RightIndexFingerCoordinatesHostView: View {
    @ObservedObject var peerManager = PeerManager()
    @State var isCommunication = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack {
            Text("3. 右手の人差し指の位置を確認").font(.title)
            Divider()
            
            Text("開始ボタンを押しながら右手の人差し指で相手の右手の人差し指に触れてください")
            
            Button(action: {
                start()
            }){
                Text("開始")
            }
            .disabled(isCommunication)
            
            Spacer()
            
            if isCommunication {
                Text("右手の人差し指同士で触れられていましたか？").font(.title2)
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
            
            Text(errorMessage)
            
            Spacer()
        }
        .onChange(of: peerManager.receivedMessage){
            onChangeReceivedMessage(receivedMessage: peerManager.receivedMessage)
        }
    }
    
    func start() {
        peerManager.sendMessage("reqRightIndexFingerCoordinates")
        peerManager.isUpdatePeerManagerRightIndexFingerCoordinates = false
        Thread.sleep(forTimeInterval: 0.1)
    }
    
    func checkFingerSuccess() {
        peerManager.sendMessage("successRightIndexFingerCoordinates")
    }
    
    func checkFingerFailure() {
        peerManager.sendMessage("reset")
        peerManager.isUpdatePeerManagerRightIndexFingerCoordinates = true
        isCommunication = false
    }
    
    func onChangeReceivedMessage(receivedMessage: String){
        if (peerManager.receivedMessage.hasPrefix("resRightIndexFingerCoordinates")){
            receiveResRightIndexFingerCoordinates()
        } else if (peerManager.receivedMessage == "receivedSuccessRightIndexFingerCoordinates") {
            receiveReceivedSuccessRightIndexFingerCoordinates()
        } else if (peerManager.receivedMessage.hasPrefix("error:")) {
            receiveError()
        }
    }
    
    func receiveResRightIndexFingerCoordinates() {
        let receivedMessage = peerManager.receivedMessage.replacingOccurrences(of: "resRightIndexFingerCoordinates", with: "")
        let data = receivedMessage.data(using: .utf8)!
        let rightIndexFingerCoordinatesCodable = try! JSONDecoder().decode(RightIndexFingerCoordinatesCodable.self, from: data)
        peerManager.rightIndexFingerCoordinates = RightIndexFingerCoordinates(rightIndexFingerCoordinatesCodable: rightIndexFingerCoordinatesCodable)
        isCommunication = true
    }
    
    func receiveReceivedSuccessRightIndexFingerCoordinates() {
        peerManager.transformationMatrixPreparationState = .bothIndexFingerCoordinateHost
    }
    
    func receiveError() {
        errorMessage = peerManager.receivedMessage
    }
}
