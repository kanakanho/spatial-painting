//
//  SelectingPeerHostView.swift
//  multipeer-share-coordinate-throw-ball
//
//  Created by blueken on 2025/01/22.
//

import SwiftUI

struct SelectingPeerHostView: View {
    @ObservedObject var peerManager = PeerManager()
    @State var peerIDHash: Int!
    
    var body: some View {
        VStack {
            Text("2. 近くにいる人を選択").font(.title)
            Divider()
            Picker("", selection: $peerIDHash) {
                Text("選ぶ").tag(nil as Int?)
                ForEach(peerManager.session.connectedPeers, id: \.hash) { peerId in
                    Text(String(peerId.hash)).tag(peerId.hash)
                }
            }
            Spacer()
            Button(action: {
                confirmSelectClient()
            }){
                Text("選択した相手を確定")
            }
            
            Button(action: {
                peerManager.transformationMatrixPreparationState = .initial
            }){
                Text("設定の最初に戻る")
            }
        }
        .onChange(of: peerManager.receivedMessage){
            onChangeReceivedMessage(receivedMessage: peerManager.receivedMessage)
        }
    }
    
    func confirmSelectClient(){
        if peerIDHash != nil {
            print(peerManager.session.connectedPeers.map{ $0.hash })
            peerManager.addSendMessagePeer(peerIDHash: peerIDHash)
            let peerIDHashStr = String(peerManager.peerID.hash)
            peerManager.sendMessage("selectClient:\(peerIDHashStr)")
        }
    }
    
    func onChangeReceivedMessage(receivedMessage: String){
        if (peerManager.receivedMessage == "receivedSelect") {
            peerManager.transformationMatrixPreparationState =  .rightIndexFingerCoordinatesHost
        }
    }
}
