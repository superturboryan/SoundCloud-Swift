//
//  SoundCloud.swift
//  SoundCloud
//
//  Created by Ryan Forsyth on 2023-10-18.
//

import AuthenticationServices
import OSLog

final public class SoundCloud {
            
    private let config: SoundCloud.Config
    private let decoder = JSONDecoder()
    private let tokenDAO = KeychainDAO<TokenResponse>("OAuthTokenResponse")
    
    public init(_ config: SoundCloud.Config) {
        self.config = config
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        if let authTokens = try? tokenDAO.get() {
            Logger.auth.info("💾 Loaded saved access token: \(authTokens.accessToken, privacy: .private)")
        }
    }
}

// MARK: - Auth 🔐
public extension SoundCloud {
    ///  Dictionary with refreshed authorization token to be used as `URLRequest` header.
    ///
    ///  **This getter will attempt to refresh the access token first if it is expired**,
    ///  throwing an error if it fails to refresh the token or doesn't find any persisted token.
    var authHeader: [String : String] { get async throws {
        guard let savedAuthTokens = try? tokenDAO.get() else {
            throw Error.userNotAuthorized
        }
        if savedAuthTokens.isExpired {
            Logger.auth.warning("⏰ Access token expired at: \(savedAuthTokens.expiryDate!)")
            do {
                try await refreshAuthTokens()
            } catch {
                throw Error.refreshingExpiredAuthTokens
            }
        }
        let validAuthTokens = try! tokenDAO.get()
        return ["Authorization" : "Bearer " + (validAuthTokens.accessToken)]
    }}
    
    func login() async throws {
        do {
            let authCode = try await getAuthCode()
            let newAuthTokens = try await getNewAuthTokens(using: authCode)
            saveTokensWithCreationDate(newAuthTokens)
        } catch(ASWebAuthenticationSession.Error.cancelledLogin) {
            throw Error.cancelledLogin
        } catch {
            throw Error.loggingIn
        }
    }
    
    func logout() {
        try? tokenDAO.delete()
    }
}

// MARK: - My User 💁
public extension SoundCloud {
    func getMyUser() async throws -> User {
        try await get(.myUser())
    }
    
    func getUsersImFollowing() async throws -> Page<User> {
        try await get(.usersImFollowing())
    }
    
    func getMyLikedTracks() async throws -> Page<Track> {
        try await get(.myLikedTracks())
    }
    
    func getMyFollowingsRecentlyPosted() async throws -> [Track] {
        try await get(.myFollowingsRecentlyPosted())
    }
    
    func getMyPlaylistsWithoutTracks() async throws -> [Playlist] {
        try await get(.myPlaylists())
    }
    
    func getMyLikedPlaylistsWithoutTracks() async throws -> [Playlist] {
        try await get(.myLikedPlaylists())
    }
}

// MARK: - Tracks 💿
public extension SoundCloud {
    func getTracksForPlaylist(_ id: Int) async throws -> Page<Track> {
        try await get(.tracksForPlaylist(id))
    }
    
    func getTracksForUser(_ id: Int, _ limit: Int = 20) async throws -> Page<Track> {
        try await get(.tracksForUser(id, limit))
    }
    
    func getLikedTracksForUser(_ id: Int, _ limit: Int = 20) async throws -> Page<Track> {
        try await get(.likedTracksForUser(id, limit))
    }
    
    func getStreamInfoForTrack(with id: Int) async throws -> StreamInfo {
        try await get(.streamInfoForTrack(id))
    }
}

// MARK: - Search 🕵️
public extension SoundCloud {
    func searchTracks(_ query: String, _ limit: Int = 20) async throws -> Page<Track> {
        try await get(.searchTracks(query, limit))
    }
    
    func searchPlaylists(_ query: String, _ limit: Int = 20) async throws -> Page<Playlist> {
        try await get(.searchPlaylists(query, limit))
    }
    
    func searchUsers(_ query: String, _ limit: Int = 20) async throws -> Page<User> {
        try await get(.searchUsers(query, limit))
    }
}

// MARK: - Like + Follow 🧡
public extension SoundCloud {
    func likeTrack(_ likedTrack: Track) async throws {
        try await get(.likeTrack(likedTrack.id))
    }
    
    func unlikeTrack(_ unlikedTrack: Track) async throws {
        try await get(.unlikeTrack(unlikedTrack.id))
    }
    
    func likePlaylist(_ playlist: Playlist) async throws {
        try await get(.likePlaylist(playlist.id))
    }
    
    func unlikePlaylist(_ playlist: Playlist) async throws {
        try await get(.unlikePlaylist(playlist.id))
    }
    
    func followUser(_ user: User) async throws {
        try await get(.followUser(user.id))
    }
    
    func unfollowUser(_ user: User) async throws {
        try await get(.unfollowUser(user.id))
    }
}

// MARK: Miscellaneous ✨
public extension SoundCloud {
    func pageOfItems<ItemType>(for href: String) async throws -> Page<ItemType> {
        try await get(.getNextPage(href))
    }
}

// MARK: - Private Auth 🙈
private extension SoundCloud {
    func getAuthCode() async throws -> String {
        let authorizeURL = config.apiURL
        + "connect"
        + "?client_id=\(config.clientId)"
        + "&redirect_uri=\(config.redirectURI)"
        + "&response_type=code"
        
        #if os(iOS)
        return try await ASWebAuthenticationSession.getAuthCode(
            from: authorizeURL,
            with: config.redirectURI,
            ephemeralSession: false
        )
        #else
        return try await ASWebAuthenticationSession.getAuthCode(
            from: authorizeURL,
            with: config.redirectURI
        )
        #endif
    }
    
    func getNewAuthTokens(using authCode: String) async throws -> (TokenResponse) {
        let tokenResponse = try await get(.accessToken(authCode, config.clientId, config.clientSecret, config.redirectURI))
        Logger.auth.info("🌟 Received new access token: \(tokenResponse.accessToken, privacy: .private)")
        return tokenResponse
    }
    
    func refreshAuthTokens() async throws {
        guard let savedRefreshToken = try? tokenDAO.get().refreshToken else {
            throw Error.userNotAuthorized
        }
        let newTokens = try await get(.refreshToken(savedRefreshToken, config.clientId, config.clientSecret, config.redirectURI))
        Logger.auth.info("♻️ Refreshed access token: \(newTokens.accessToken, privacy: .private)")
        saveTokensWithCreationDate(newTokens)
    }
    
    func saveTokensWithCreationDate(_ tokens: TokenResponse) {
        var tokensWithDate = tokens
        tokensWithDate.expiryDate = tokens.expiresIn.dateWithSecondsAdded(to: Date())
        try? tokenDAO.save(tokensWithDate)
    }
}

// MARK: - API request 🌍
private extension SoundCloud {
    @discardableResult
    func get<T: Decodable>(_ request: Request<T>) async throws -> T {
        try await fetchData(from: authorized(request))
    }
    
    func fetchData<T: Decodable>(from request: URLRequest) async throws -> T {
        guard let (data, response) = try? await URLSession.shared.data(for: request) else {
            throw Error.noInternet // Is no internet the only case here?
        }
        let statusCodeInt = (response as! HTTPURLResponse).statusCode
        let statusCode = StatusCode(rawValue: statusCodeInt) ?? .unknown
        guard statusCode != .unauthorized else {
            throw Error.userNotAuthorized
        }
        guard statusCode != .tooManyRequests else {
            throw Error.tooManyRequests
        }
        guard !statusCode.errorOccurred else {
            throw Error.network(statusCode)
        }
        guard let decodedObject = try? decoder.decode(T.self, from: data) else {
            throw Error.decoding
        }
        return decodedObject
    }
    
    func authorized<T>(_ scRequest: Request<T>) async throws -> URLRequest {
        guard let urlWithPath = URL(string: config.apiURL + scRequest.path),
              var components = URLComponents(url: urlWithPath, resolvingAgainstBaseURL: false)
        else {
            throw Error.invalidURL
        }
        components.queryItems = scRequest.queryParameters?.map { URLQueryItem(name: $0, value: $1) }
        
        var request = URLRequest(url: components.url!)
        if scRequest.isForHref {
            request = URLRequest(url: URL(string: scRequest.path)!)
        }

        request.httpMethod = scRequest.httpMethod
        if scRequest.shouldUseAuthHeader {
            request.allHTTPHeaderFields = try await authHeader // Will refresh tokens if necessary
        }
        return request
    }
}
