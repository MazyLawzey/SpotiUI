//
//  SettingsView.swift
//  SpotiUI
//
//  Created by Mazy Lawzey on 28.03.2026.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("pollingInterval") private var pollingInterval: Double = 3.0
    @AppStorage("showRemainingTime") private var showRemainingTime: Bool = true
    @AppStorage("hapticEnabled") private var hapticEnabled: Bool = true

    var body: some View {
        Form {
            Section("Account") {
                if SpotifyAuth.isAuthenticated {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Connected to Spotify")
                            .foregroundStyle(.primary)
                        Spacer()
                        Button("Log out") {
                            SpotifyPlayer.shared.logout()
                        }
                        .foregroundStyle(.red)
                    }
                } else {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Text("Not connected")
                        Spacer()
                        Button("Log in") {
                            SpotifyPlayer.shared.login()
                        }
                    }
                }
            }

            Section("Player") {
                HStack {
                    Text("Update Interval")
                    Spacer()
                    Picker("", selection: $pollingInterval) {
                        Text("1 sec").tag(1.0)
                        Text("3 sec").tag(3.0)
                        Text("5 sec").tag(5.0)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                    .onChange(of: pollingInterval) { _ in
                        SpotifyPlayer.shared.startPolling()
                    }
                }

                Toggle("Show Remaining Time", isOn: $showRemainingTime)
                Toggle("Haptic Feedback", isOn: $hapticEnabled)
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Spotify API")
                    Spacer()
                    Text("Web API v1")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 320)
    }
}
