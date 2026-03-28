//
//  SpotifySearch.swift
//  SpotiUI
//
//  Created by Mazy Lawzey on 28.03.2026.
//

import Foundation

struct SpotifySearchResult: Codable {
    let tracks: SpotifyTrackPage
}

struct SpotifyTrackPage: Codable {
    let items: [SpotifyTrack]
}

extension SpotifyAPIClient {
    func search(query: String, offset: Int = 0) async throws -> [SpotifyTrack] {
        var components = URLComponents(string: "https://api.spotify.com/v1/search")!
        components.queryItems = [
            .init(name: "q",    value: query),
            .init(name: "type", value: "track"),
        ]

        guard let baseURL = components.url else { throw APIError.invalidURL }

        let url = URL(string: baseURL.absoluteString + "&limit=10&offset=\(offset)")!

        let token = try await SpotifyAuth.validAccessToken()
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0

        if status == 401 { throw APIError.unauthorized }
        if !(200..<300).contains(status) {
            let errorBody = String(data: data, encoding: .utf8) ?? "no body"
            print("❌ Search error body: \(errorBody)")
            throw APIError.httpError(status)
        }

        let result = try JSONDecoder().decode(SpotifySearchResult.self, from: data)
        return result.tracks.items
    }
}
