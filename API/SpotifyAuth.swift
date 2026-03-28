//
//  SpotifyAuth.swift
//  SpotiUI
//
//  Created by Mazy Lawzey on 28.03.2026.
//

import Foundation
import CryptoKit
import AppKit

final class SpotifyAuth {

    
    static let clientId     = ""
    static let redirectURI  = "spotiui://callback"

    private static let tokenKey        = "spotify_access_token"
    private static let refreshKey      = "spotify_refresh_token"
    private static let expiryKey       = "spotify_token_expiry"
    private static let verifierKey     = "spotify_code_verifier"

    private static let scopes = [
        "user-read-playback-state",
        "user-modify-playback-state",
        "user-read-currently-playing",
        "streaming",
        "playlist-read-private",
        "user-library-read"
    ].joined(separator: " ")

    // MARK: - PKCE helpers

    static func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 64)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64URLEncoded()
    }

    static func codeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64URLEncoded()
    }

    // MARK: - Authorization URL

    static func buildAuthURL() -> URL? {
        let verifier = generateCodeVerifier()
        UserDefaults.standard.set(verifier, forKey: verifierKey)

        let challenge = codeChallenge(from: verifier)

        var components = URLComponents(string: "https://accounts.spotify.com/authorize")!
        components.queryItems = [
            .init(name: "client_id",             value: clientId),
            .init(name: "response_type",         value: "code"),
            .init(name: "redirect_uri",          value: redirectURI),
            .init(name: "scope",                 value: scopes),
            .init(name: "code_challenge_method", value: "S256"),
            .init(name: "code_challenge",        value: challenge),
        ]
        return components.url
    }

    // MARK: - Token Exchange

    static func exchangeCode(_ code: String) async throws -> SpotifyTokenResponse {
        guard let verifier = UserDefaults.standard.string(forKey: verifierKey) else {
            throw AuthError.missingVerifier
        }

        var request = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "grant_type":    "authorization_code",
            "code":          code,
            "redirect_uri":  redirectURI,
            "client_id":     clientId,
            "code_verifier": verifier
        ]
        request.httpBody = body.urlEncoded

        let (data, _) = try await URLSession.shared.data(for: request)
        let token = try JSONDecoder().decode(SpotifyTokenResponse.self, from: data)
        saveToken(token)
        return token
    }

    // MARK: - Token Refresh

    static func refreshAccessToken() async throws -> String {
        guard let refresh = UserDefaults.standard.string(forKey: refreshKey) else {
            throw AuthError.notAuthenticated
        }

        var request = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "grant_type":    "refresh_token",
            "refresh_token": refresh,
            "client_id":     clientId
        ]
        request.httpBody = body.urlEncoded

        let (data, _) = try await URLSession.shared.data(for: request)
        let token = try JSONDecoder().decode(SpotifyTokenResponse.self, from: data)
        saveToken(token)
        return token.accessToken
    }

    // MARK: - Token Access

    static func validAccessToken() async throws -> String {
        if let expiry = UserDefaults.standard.object(forKey: expiryKey) as? Date,
           expiry > Date().addingTimeInterval(60),
           let token = UserDefaults.standard.string(forKey: tokenKey) {
            return token
        }
        return try await refreshAccessToken()
    }

    static var isAuthenticated: Bool {
        UserDefaults.standard.string(forKey: tokenKey) != nil
    }

    // MARK: - Persistence

    private static func saveToken(_ token: SpotifyTokenResponse) {
        UserDefaults.standard.set(token.accessToken, forKey: tokenKey)
        if let refresh = token.refreshToken {
            UserDefaults.standard.set(refresh, forKey: refreshKey)
        }
        let expiry = Date().addingTimeInterval(Double(token.expiresIn))
        UserDefaults.standard.set(expiry, forKey: expiryKey)
    }

    static func logout() {
        [tokenKey, refreshKey, expiryKey, verifierKey].forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
    }

    // MARK: - Open Auth in Browser

    static func openAuthPage() {
        guard let url = buildAuthURL() else { return }
        NSWorkspace.shared.open(url)
    }

    enum AuthError: LocalizedError {
        case missingVerifier
        case notAuthenticated

        var errorDescription: String? {
            switch self {
            case .missingVerifier:   return "PKCE code verifier not found"
            case .notAuthenticated:  return "User is not authenticated"
            }
        }
    }
}

// MARK: - Helpers

private extension Data {
    func base64URLEncoded() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

private extension Dictionary where Key == String, Value == String {
    var urlEncoded: Data? {
        map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)
    }
}
