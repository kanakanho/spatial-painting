//
//  SelectingPeerClientView.swift
//  multipeer-share-coordinate-throw-ball
//
//  Created by blueken on 2025/01/22.
//

import SwiftUI

struct SelectingPeerClientView: View {
    @ObservedObject var peerManager = PeerManager()
    
    var body: some View {
        VStack {
            Text("2. 近くにいる人を選択").font(.title)
            Divider()
            Text("ホストからの選択を待っています")
            
            Spacer()
            
            Button(action: {
                returnInitial()
            }){
                Text("設定の最初に戻る")
            }
        }
        .onChange(of: peerManager.receivedMessage){
            onChangeReceivedMessage(receivedMessage: peerManager.receivedMessage)
        }
    }
    
    func returnInitial(){
        peerManager.transformationMatrixPreparationState = .initial
    }
    
    func onChangeReceivedMessage(receivedMessage: String){
        if (peerManager.receivedMessage.hasPrefix("selectClient:")) {
            let peerIDHash = peerManager.receivedMessage.replacingOccurrences(of: "selectClient:", with: "")
            let peerIDHashInt = Int(peerIDHash) ?? 0
            peerManager.addSendMessagePeer(peerIDHash: peerIDHashInt)
            peerManager.sendMessage("receivedSelect")
            peerManager.transformationMatrixPreparationState = .rightIndexFingerCoordinatesClient
        }
    }
}

