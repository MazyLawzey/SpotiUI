//
//  SpotifyPlayer.swift
//  SpotiUI
//
//  Created by Mazy Lawzey on 28.03.2026.
//

import Foundation
import AppKit
import Combine

@MainActor
final class SpotifyPlayer: ObservableObject {

    static let shared = SpotifyPlayer()

    @Published var trackName: String     = "Name of the track"
    @Published var artistName: String    = "Artist name"
    @Published var albumArt: NSImage?    = nil
    @Published var isPlaying: Bool       = false
    @Published var progress: Double      = 0.0
    @Published var positionMs: Int       = 0
    @Published var durationMs: Int       = 1
    @Published var shuffleOn: Bool       = false
    @Published var repeatMode: String    = "off"
    @Published var isAuthenticated: Bool = false

    private var pollTask: Task<Void, Never>?
    private var currentTrackId: String?

    private init() {
        isAuthenticated = SpotifyAuth.isAuthenticated
    }

    // MARK: - Auth

    func login() {
        SpotifyAuth.openAuthPage()
    }

    func handleCallback(url: URL) {
        print("📲 Callback URL: \(url)")
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else {
            print("❌ No code in URL")
            return
        }

        Task {
            do {
                try await SpotifyAuth.exchangeCode(code)
                await MainActor.run {
                    isAuthenticated = true
                    print("✅ Auth success")
                }
                startPolling()
            } catch {
                print("❌ Auth error: \(error)")
            }
        }
    }

    func logout() {
        stopPolling()
        SpotifyAuth.logout()
        isAuthenticated = false
        resetState()
    }

    // MARK: - Polling

    func startPolling() {
        stopPolling()
        isAuthenticated = SpotifyAuth.isAuthenticated
        guard isAuthenticated else { return }

        pollTask = Task {
            while !Task.isCancelled {
                await fetchPlaybackState()
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    // MARK: - Playback Fetch

    func fetchPlaybackState() async {
        do {
            guard let state = try await SpotifyAPIClient.shared.getCurrentPlayback() else {
                return
            }

            isPlaying  = state.isPlaying
            shuffleOn  = state.shuffleState
            repeatMode = state.repeatState

            if let track = state.item {
                trackName  = track.name
                artistName = track.artistNames
                durationMs = track.durationMs
                positionMs = state.progressMs ?? 0
                progress   = durationMs > 0 ? Double(positionMs) / Double(durationMs) : 0

                if track.id != currentTrackId {
                    currentTrackId = track.id
                    if let imageURL = track.album.bestImage?.url {
                        let artData = try await SpotifyAPIClient.shared.fetchAlbumArt(from: imageURL)
                        albumArt = NSImage(data: artData)
                    }
                }
            }
        } catch {
            print("Playback fetch error: \(error)")
        }
    }

    // MARK: - Controls

    func togglePlayPause() {
        Task {
            do {
                isPlaying
                    ? try await SpotifyAPIClient.shared.pause()
                    : try await SpotifyAPIClient.shared.play()
                isPlaying.toggle()
            } catch { print(error) }
        }
    }

    func nextTrack() {
        Task {
            try? await SpotifyAPIClient.shared.nextTrack()
            try? await Task.sleep(nanoseconds: 500_000_000)
            await fetchPlaybackState()
        }
    }

    func previousTrack() {
        Task {
            try? await SpotifyAPIClient.shared.previousTrack()
            try? await Task.sleep(nanoseconds: 500_000_000)
            await fetchPlaybackState()
        }
    }

    func seek(to fraction: Double) {
        let ms = Int(fraction * Double(durationMs))
        Task { try? await SpotifyAPIClient.shared.seek(toPositionMs: ms) }
    }

    func toggleShuffle() {
        Task {
            try? await SpotifyAPIClient.shared.setShuffle(!shuffleOn)
            shuffleOn.toggle()
        }
    }

    func cycleRepeat() {
        let next: String
        switch repeatMode {
        case "off":     next = "context"
        case "context": next = "track"
        default:        next = "off"
        }
        Task {
            try? await SpotifyAPIClient.shared.setRepeat(next)
            repeatMode = next
        }
    }

    // MARK: - Helpers

    func formattedTime(_ ms: Int) -> String {
        let secs = ms / 1000
        return String(format: "%d:%02d", secs / 60, secs % 60)
    }

    var remainingTime: String {
        let remaining = durationMs - positionMs
        return "-\(formattedTime(max(0, remaining)))"
    }

    private func resetState() {
        trackName      = "Name of the track"
        artistName     = "Artist name"
        albumArt       = nil
        isPlaying      = false
        progress       = 0
        positionMs     = 0
        durationMs     = 1
        currentTrackId = nil
    }
}
