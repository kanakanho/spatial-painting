//
//  TransformationMatrixPreparationView.swift
//  multipeer-share-coordinate-throw-ball
//
//  Created by blueken on 2024/12/18.
//

import SwiftUI

struct TransformationMatrixPreparationView: View {
    @ObservedObject var peerManager = PeerManager()
    @Binding var sharedCoordinateState: SharedCoordinateState
    var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var time: String = ""
    
    var body: some View {
        VStack{
            HStack{
                Text("MyId:\(peerManager.peerID.hash)").font(.title)
                Text(time)
            }
            Divider()
            NavigationStack {
                switch peerManager.transformationMatrixPreparationState {
                case .initial:
                    InitialView(peerManager:peerManager)
                case .searching:
                    SearchingPeerView(peerManager:peerManager)
                case .selectingHost:
                    SelectingPeerHostView(peerManager:peerManager)
                case .selectingClient:
                    SelectingPeerClientView(peerManager:peerManager)
                case .rightIndexFingerCoordinatesHost:
                    RightIndexFingerCoordinatesHostView(peerManager:peerManager)
                case .rightIndexFingerCoordinatesClient:
                    RightIndexFingerCoordinatesClientView(peerManager:peerManager)
                case .bothIndexFingerCoordinateHost:
                    BothIndexFingerCoordinateHostView(peerManager:peerManager)
                case .bothIndexFingerCoordinateClient:
                    BothIndexFingerCoordinateClientView(peerManager:peerManager)
                case .confirm:
                    ConfirmView(peerManager:peerManager, sharedCoordinateState: $sharedCoordinateState)
                case .prepared:
                    Text("prepared")
                }
            }
            Spacer()
            Divider()
            Text("Received Messages:\(peerManager.receivedMessage)")
                .font(.headline)
        }.onAppear {
            peerManager.start()
        }
        .onReceive(timer) { _ in
            self.time = "\(Date())"
        }
    }
}
