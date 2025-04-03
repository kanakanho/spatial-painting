//
//  ContentView.swift
//  multipeer-share-coordinate-throw-ball
//
//  Created by blueken on 2024/12/20.
//

import SwiftUI
import RealityKit
import RealityKitContent

enum SharedCoordinateState {
    case prepare
    case sharing
    case shared
}

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @ObservedObject var peerManager = PeerManager()
    @State private var sharedCoordinateState: SharedCoordinateState = .prepare
    
    var body: some View {
        VStack {
            NavigationStack {
                switch sharedCoordinateState {
                case .prepare:
                    ToggleImmersiveSpaceButton()
                        .onChange(of: appModel.immersiveSpaceState){
                            if (appModel.immersiveSpaceState == .open){
                                sharedCoordinateState = .sharing
                            }
                        }
                case .sharing:
                    VStack{
                        TransformationMatrixPreparationView(peerManager:peerManager,sharedCoordinateState: $sharedCoordinateState)
                    }
                case .shared:
                    Text("Shared Coordinate Ready")
                }
            }
            Spacer()
        }
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
