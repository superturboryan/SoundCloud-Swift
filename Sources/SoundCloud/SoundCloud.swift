//
//  SoundCloud.swift
//  SoundCloud
//
//  Created by Ryan Forsyth on 2023-10-18.
//

import AuthenticationServices
import Combine
import CryptoKit
import OSLog

/// Handles the logic for making authenticated requests to the SoundCloud API.
///
/// - parameter config: Contains parameters for interacting with SoundCloud API (base URL, client ID, secret, redirect URI)
/// - parameter tokenDAO: Data access object for persisting authentication tokens, defaults to **KeychainDAO**
///
/// Use an instance of `SoundCloud` to allow users to login with their SoundCloud account and make authenticated
/// requests for streaming content and acessing track, artist, and playlist data from SoundCloud.
///
/// - Important: OAuth tokens are stored in the `Keychain` by default.
/// - SeeAlso: Visit the [SoundCloud API Explorer](https://developers.soundcloud.com/docs/api/explorer/open-api#/) for more information.
public final class SoundCloud {
            
    private let config: Config
    private let tokenDAO: any DAO<TokenResponse>
    private let decoder = JSONDecoder()
    private let urlSession = URLSession(configuration: .default)
    public var subscriptions = Set<AnyCancellable>()
    
    public init(
        _ config: Config,
        _ tokenDAO: any DAO<TokenResponse> = KeychainDAO<TokenResponse>("OAuthTokenResponse")
    ) {
        self.config = config
        self.tokenDAO = tokenDAO
        decoder.keyDecodingStrategy = .convertFromSnakeCase // API keys use snake case
        logCurrentAuthToken()
    }
}

// MARK: - Public 👀
public extension SoundCloud {
    
    // MARK: - Auth 🔐
    /// Performs the `OAuth` authentication flow and persists the resulting access tokens.
    ///
    /// This method does three things:
    /// 1. Presents the SoundCloud login page inside a browser window managed by `ASWebAuthenticationSession` to get the **authorization code**.
    /// 2. Exchanges the authorization code for **OAuth access tokens** specific to the SoundCloud user.
    /// 3. Persists the **access tokens** using the data access object.
    ///
    /// - Throws: **`.loggingIn`**  if an error occurred while fetching the authorization code or authentication tokens.
    @discardableResult
    func login() async throws -> TokenResponse {
        do {
            let codeVerifier = PKCE.generateCodeVerifier()
            let codeChallenge = try PKCE.generateCodeChallenge(using: codeVerifier)
            let authorizationURL = makeOAuthAuthorizationURL(config.clientId, config.redirectURI, codeChallenge)
            let authorizationCode = try await getAuthorizationCode(from: authorizationURL, with: codeChallenge)
            let newAuthTokens = try await getAuthenticationTokens(with: authorizationCode, and: codeVerifier)
            saveTokensWithCreationDate(newAuthTokens)
            return newAuthTokens
        } catch(ASWebAuthenticationSession.Error.cancelledLogin) {
            throw Error.cancelledLogin
        } catch {
            throw Error.loggingIn
        }
    }
    
    /// Deletes the persisted access tokens.
    func logout() {
        try? tokenDAO.delete()
    }
    
    ///  Dictionary with valid OAuth 2.0 access token.
    ///
    ///  - Important: This **async** getter will first attempt to refresh the access token if it is expired.
    ///  - Throws: **`.userNotAuthorized`**  if no access token exists.
    ///  - Throws: **`.refreshingExpiredAuthTokens`** if refreshing fails.
    var authenticatedHeader: [String : String] { get async throws {
        guard let savedAuthTokens = try? tokenDAO.get() else {
            throw Error.userNotAuthorized
        }
        if savedAuthTokens.isExpired {
            logAuthTokenExpired(savedAuthTokens.expiryDate!)
            try await refreshAuthTokens()
        }
        let validAuthTokens = try! tokenDAO.get()
        return ["Authorization" : "Bearer " + (validAuthTokens.accessToken)]
    }}

    // MARK: - My User 🕺
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

    // MARK: - Tracks 💿
    func getTracksForPlaylist(_ id: Int) async throws -> Page<Track> {
        try await get(.tracksForPlaylist(id))
    }
    
    func getTracksForUser(_ id: Int, _ limit: Int = 20) async throws -> Page<Track> {
        try await get(.tracksForUser(id, limit))
    }
    
    func getLikedTracksForUser(_ id: Int, _ limit: Int = 20) async throws -> Page<Track> {
        try await get(.likedTracksForUser(id, limit))
    }
    
    func getRelatedTracks(_ id: Int, _ limit: Int = 20) async throws -> Page<Track> {
        return try await get(.relatedTracks(id, limit))
    }

    // MARK: - Search 🕵️
    func searchTracks(_ query: String, _ limit: Int = 20) async throws -> Page<Track> {
        try await get(.searchTracks(query, limit))
    }
    
    func searchPlaylists(_ query: String, _ limit: Int = 20) async throws -> Page<Playlist> {
        try await get(.searchPlaylists(query, limit))
    }
    
    func searchUsers(_ query: String, _ limit: Int = 20) async throws -> Page<User> {
        try await get(.searchUsers(query, limit))
    }

    // MARK: - Like + Follow 🧡
    /// - Warning: The liked track may not be returned when calling `getMyLikedTracks()` since the API
    /// appears to cache responses, consider keeping track of the liked tracks using a local array.
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

    // MARK: - Miscellaneous ✨
    func pageOfItems<ItemType>(for href: String) async throws -> Page<ItemType> {
        try await get(.getNextPage(href))
    }
    
    func getStreamInfoForTrack(with id: Int) async throws -> StreamInfo {
        try await get(.streamInfoForTrack(id))
    }
    
    func handleNewAuthTokensNotification(_ notification: Notification) {
        guard // Check notification.name?
            let tokenData = notification.object as? Data,
            let tokens = try? decoder.decode(TokenResponse.self, from: tokenData)
        else {
            // Log unexpected notification?
            return
        }
        saveTokensWithCreationDate(tokens)
    }
}

// MARK: - Private 🚫👀
private extension SoundCloud {
    
    // MARK: - Auth 🔐
    func getAuthorizationCode(from url: URL, with codeChallenge: String) async throws -> String {
        try await ASWebAuthenticationSession.getAuthorizationCode(
            from: url,
            with: config.redirectURI,
            ephemeralSession: false
        )
    }
    
    func getAuthenticationTokens(with authCode: String, and codeVerifier: String) async throws -> (TokenResponse) {
        let tokenResponse = try await get(.accessToken(authCode, config.clientId, config.clientSecret, config.redirectURI, codeVerifier))
        logNewAuthToken(tokenResponse.accessToken)
        return tokenResponse
    }
    
    func refreshAuthTokens() async throws {
        guard let savedRefreshToken = try? tokenDAO.get().refreshToken else {
            throw Error.userNotAuthorized
        }
        let refreshedTokens = try await get(.refreshToken(savedRefreshToken, config.clientId, config.clientSecret, config.redirectURI))
        logNewAuthToken(refreshedTokens.accessToken)
        saveTokensWithCreationDate(refreshedTokens)
    }
    
    func saveTokensWithCreationDate(_ tokens: TokenResponse) {
        var tokensWithDate = tokens
        tokensWithDate.expiryDate = tokens.expiresIn.dateWithSecondsAdded(to: Date())
        try? tokenDAO.save(tokensWithDate)
    }

    // MARK: - API request 🌍
    @discardableResult
    func get<T: Decodable>(_ request: Request<T>) async throws -> T {
        try await fetchData(using: authorized(request))
    }
    
    func fetchData<T: Decodable>(using request: URLRequest) async throws -> T {
        guard let (data, response) = try? await urlSession.data(for: request) else {
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
        var request = scRequest.urlRequest
        if scRequest.shouldUseAuthHeader {
            request.allHTTPHeaderFields = try await authenticatedHeader // Will refresh tokens if necessary
        }
        return request
    }
    
    private func makeOAuthAuthorizationURL(_ clientID: String, _ redirectURI: String, _ codeChallenge: String) -> URL {
        let baseURLWithPath = "https://secure.soundcloud.com/authorize"
        var components = URLComponents(string: baseURLWithPath)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]
        return components.url!
    }
    
    // MARK: - Debug logging 📝
    func logCurrentAuthToken() {
        let token = try? tokenDAO.get().accessToken
        Logger.auth.info("💾 Current access token: \(token ?? "None", privacy: .private)")
    }
    
    func logNewAuthToken(_ token: String) {
        Logger.auth.info("🌟 Received new access token: \(token, privacy: .private)")
    }
    
    func logAuthTokenExpired(_ date: Date) {
        Logger.auth.warning("⏰ Access token expired at: \(date)")
    }
}
