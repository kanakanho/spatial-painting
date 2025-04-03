//
//  spatial_paintingApp.swift
//  spatial-painting
//
//  Created by blueken on 2025/03/18.
//

import SwiftUI

@main
struct spatial_paintingApp: App {

    @State private var appModel = AppModel()
    @State private var model = ViewModel()

    @StateObject private var peerManager = PeerManager()

    var body: some Scene {
        WindowGroup {
            ContentView(peerManager:peerManager)
                .environment(appModel)
        }

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView(peerManager:peerManager)
                .environment(model)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
     }
}
