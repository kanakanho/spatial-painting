//
//  SearchingPeerView.swift
//  multipeer-share-coordinate-throw-ball
//
//  Created by blueken on 2025/01/22.
//

import SwiftUI

struct SearchingPeerView: View {
    @ObservedObject var peerManager = PeerManager()
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack {
            Text("1. 近くにいる人を探す").font(.title)
            Divider()
            Button(action:{
                searchPeer()
            }){
                Text("探す").font(.title2)
            }
            
            Spacer()
            
            if !errorMessage.isEmpty {
                Text(errorMessage).foregroundColor(.red)
                Button(action: {
                    returnToInitial()
                }){
                    Text("設定の最初に戻る")
                }
            }
            
        }
    }
    
    func searchPeer() {
        let peers = peerManager.session.connectedPeers
        // 自分のhash値が一番大きいか
        let isHost = peers.allSatisfy { peer in
            peerManager.peerID.hash > peer.hash
        }
        
        peerManager.decisionHost(isHost: isHost)
        
        peerManager.sendMessageForAll("searched")
        peerManager.transformationMatrixPreparationState = peerManager.isHost ? .selectingHost : .selectingClient
    }
    
    func returnToInitial() {
        peerManager.transformationMatrixPreparationState = .initial
    }
}
