//
//  SpotiUIApp.swift
//  SpotiUI
//
//  Created by Mazy Lawzey on 28.03.2026.
//

import SwiftUI

@main
struct SpotiUIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                      SpotifyPlayer.shared.handleCallback(url: url)
                  }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 400, height: 700)
        
        Settings {
            SettingsView()
        }
    }
}
