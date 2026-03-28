//
//  ContentView.swift
//  SpotiUI
//
//  Created by Mazy Lawzey on 28.03.2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var player = SpotifyPlayer.shared

    var body: some View {
        ZStack {
            if player.isAuthenticated {
                TabView {
                    MusicView()
                        .tabItem { Label("Player", systemImage: "play.circle.fill") }

                    SearchView()
                        .tabItem { Label("Search", systemImage: "magnifyingglass") }
                }
                .onAppear {
                    player.startPolling()
                }
            } else {
                LoginView()
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: player.isAuthenticated)
        .frame(minWidth: 350, maxWidth: 350, minHeight: 600, maxHeight: 600)
    }
}

#Preview {
    ContentView()
}
