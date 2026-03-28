//
//  SpotifyAPIClient.swift
//  SpotiUI
//
//  Created by Mazy Lawzey on 28.03.2026.
//


import Foundation

final class SpotifyAPIClient {

    static let shared = SpotifyAPIClient()
    private let baseURL = "https://api.spotify.com/v1"

    private init() {}

    // MARK: - Playback State

    func getCurrentPlayback() async throws -> SpotifyPlaybackState? {
        let data = try await get("/me/player")
        guard let data else { return nil }
        return try JSONDecoder().decode(SpotifyPlaybackState.self, from: data)
    }

    // MARK: - Playback Controls

    func play(uri: String? = nil) async throws {
        var body: Data? = nil
        if let uri {
            body = try JSONEncoder().encode(["uris": [uri]])
        }
        try await put("/me/player/play", body: body)
    }

    func pause() async throws {
        try await put("/me/player/pause")
    }

    func nextTrack() async throws {
        try await post("/me/player/next")
    }

    func previousTrack() async throws {
        try await post("/me/player/previous")
    }

    func seek(toPositionMs position: Int) async throws {
        try await put("/me/player/seek?position_ms=\(position)")
    }

    func setShuffle(_ enabled: Bool) async throws {
        try await put("/me/player/shuffle?state=\(enabled)")
    }

    func setRepeat(_ mode: String) async throws {
        // mode: "off" | "track" | "context"
        try await put("/me/player/repeat?state=\(mode)")
    }

    // MARK: - Album Art

    func fetchAlbumArt(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }

    // MARK: - Private HTTP helpers

    func get(_ path: String) async throws -> Data? {
        let token = try await SpotifyAuth.validAccessToken()
        var request = URLRequest(url: URL(string: baseURL + path)!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0

        if status == 204 { return nil }   // No content (nothing playing)
        if status == 401 { throw APIError.unauthorized }
        if !(200..<300).contains(status) { throw APIError.httpError(status) }
        return data
    }

    @discardableResult
    private func put(_ path: String, body: Data? = nil) async throws -> Data? {
        try await send("PUT", path: path, body: body)
    }

    @discardableResult
    private func post(_ path: String, body: Data? = nil) async throws -> Data? {
        try await send("POST", path: path, body: body)
    }

    private func send(_ method: String, path: String, body: Data?) async throws -> Data? {
        let token = try await SpotifyAuth.validAccessToken()
        var request = URLRequest(url: URL(string: baseURL + path)!)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 401 { throw APIError.unauthorized }
        if !(200..<300).contains(status) { throw APIError.httpError(status) }
        return data
    }

    enum APIError: LocalizedError {
        case invalidURL
        case unauthorized
        case httpError(Int)

        var errorDescription: String? {
            switch self {
            case .invalidURL:       return "Invalid URL"
            case .unauthorized:     return "Access token expired or invalid"
            case .httpError(let c): return "HTTP error: \(c)"
            }
        }
    }
}
