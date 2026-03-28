//
//  LoginView.swift
//  SpotiUI
//
//  Created by Mazy Lawzey on 28.03.2026.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var player = SpotifyPlayer.shared
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.green.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.08 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)

                Image(systemName: "music.note")
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(.green)
            }
            .padding(.bottom, 32)

            Text("SpotiUI")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Color.primary)

            Text("Log in to start listening")
                .font(.system(size: 15))
                .foregroundStyle(Color.secondary)
                .padding(.top, 8)
                .padding(.bottom, 48)

            Button {
                player.login()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18))
                    Text("Log in with Spotify")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.green)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 40)

            Text("A Spotify Premium account is required\nfor playback control and music streaming.")
                .font(.system(size: 12))
                .foregroundStyle(Color.secondary.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.top, 20)

            Spacer()
            
            Button {
                if let url = URL(string: "https://github.com/MazyLawzey/SpotiUI") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Image("Github")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { isAnimating = true }
    }
}
