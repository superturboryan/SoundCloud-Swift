//
//  SoundCloud.swift
//  SoundCloud
//
//  Created by Ryan Forsyth on 2023-10-18.
//

import AuthenticationServices
import Combine
import Consolable

/// Uniform Resource Name
///
/// See [SoundCloud developers blog article](https://developers.soundcloud.com/blog/urn-num-to-string)
public typealias URN = String

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
@Consolable("🌩️")
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
    func authenticate() async throws -> TokenResponse {
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
    
    /// Logs the user out by deleting persisted access tokens.
    ///
    /// This removes OAuth tokens stored in the Keychain (or custom `DAO` provided).
    /// After calling this, all subsequent API calls will throw `Error.userNotAuthorized`
    /// until `authenticate()` is performed again.
    func signOut() {
        try? tokenDAO.delete()
    }
    
    var authorizationHeader: [String : String] { get async throws {
        guard let savedAuthTokens = try? tokenDAO.get() else {
            throw Error.userNotAuthorized
        }
        if savedAuthTokens.isExpired {
            log("⏰ Access token expired at: \(savedAuthTokens.expiryDate!)")
            try await refreshAuthTokens()
        }
        let validAuthTokens = try! tokenDAO.get()
        return ["Authorization" : "Bearer " + (validAuthTokens.accessToken)]
    }}
    
    // MARK: - Auth 🔐
    func getAuthorizationCode(from url: URL, with codeChallenge: String) async throws -> String {
        try await ASWebAuthenticationSession.getAuthorizationCode(
            from: url,
            with: config.redirectURI,
            ephemeralSession: false
        )
    }
    
    // MARK: - My User 🕺
    /// Fetch the authenticated user's profile.
    ///
    /// - Returns: The `User` associated with the current OAuth token.
    /// - Throws: Authorization, network, or decoding errors.
    func currentUser() async throws -> User {
        try await get(.currentUser())
    }
    
    /// Fetch the users the authenticated account is following.
    ///
    /// - Returns: A paginated `Page<User>`. Use `page.nextHref` with `nextPage(from:)` to load more.
    /// - Throws: Authorization, network, or decoding errors.
    func usersIFollow() async throws -> Page<User> {
        try await get(.usersImFollowing())
    }
    
    /// Fetch your liked tracks.
    ///
    /// - Returns: A paginated `Page<Track>`. Use `page.nextHref` with `nextPage(from:)` to load more.
    /// - Throws: Authorization, network, or decoding errors.
    func likedTracks() async throws -> Page<Track> {
        try await get(.myLikedTracks())
    }
    
    /// Fetch recent tracks posted by accounts you follow.
    ///
    /// - Returns: A list of recent `Track`s from your followings.
    /// - Throws: Authorization, network, or decoding errors.
    func followingFeed() async throws -> [Track] {
        try await get(.myFollowingsRecentlyPosted())
    }
    
    /// Fetch your playlists without track items to reduce payload size.
    ///
    /// Use `tracks(inPlaylist:)` to load tracks for a given playlist.
    /// - Returns: A list of `Playlist` objects (track lists omitted).
    /// - Throws: Authorization, network, or decoding errors.
    func playlists() async throws -> [Playlist] {
        try await get(.myPlaylists())
    }
    
    /// Fetch playlists you've liked, without track items to reduce payload size.
    ///
    /// Use `tracks(inPlaylist:)` to load tracks for a given playlist.
    /// - Returns: A list of `Playlist` objects (track lists omitted).
    /// - Throws: Authorization, network, or decoding errors.
    func likedPlaylists() async throws -> [Playlist] {
        try await get(.myLikedPlaylists())
    }

    // MARK: - Tracks 💿
    /// Fetch tracks for a specific playlist.
    ///
    /// - Parameter id: The playlist URN.
    /// - Returns: A paginated `Page<Track>`. Use `page.nextHref` with `nextPage(from:)` to load more.
    /// - Throws: Authorization, network, or decoding errors.
    func tracks(inPlaylist id: URN) async throws -> Page<Track> {
        try await get(.tracksForPlaylist(id))
    }
    
    /// Fetch a user's uploaded tracks.
    ///
    /// - Parameters:
    ///   - id: The user URN.
    ///   - limit: Page size (default 20).
    /// - Returns: A paginated `Page<Track>`. Use `page.nextHref` with `nextPage(from:)` to load more.
    /// - Throws: Authorization, network, or decoding errors.
    func tracks(forUser id: URN, limit: Int = 20) async throws -> Page<Track> {
        try await get(.tracksForUser(id, limit))
    }
    
    /// Fetch tracks liked by a specific user.
    ///
    /// - Parameters:
    ///   - id: The user URN.
    ///   - limit: Page size (default 20).
    /// - Returns: A paginated `Page<Track>`. Use `page.nextHref` with `nextPage(from:)` to load more.
    /// - Throws: Authorization, network, or decoding errors.
    func likedTracks(forUser id: URN, limit: Int = 20) async throws -> Page<Track> {
        try await get(.likedTracksForUser(id, limit))
    }
    
    /// Fetch tracks related to a given track.
    ///
    /// - Parameters:
    ///   - id: The seed track URN.
    ///   - limit: Page size (default 20).
    /// - Returns: A paginated `Page<Track>`. Use `page.nextHref` with `nextPage(from:)` to load more.
    /// - Throws: Authorization, network, or decoding errors.
    func relatedTracks(to id: URN, limit: Int = 20) async throws -> Page<Track> {
        try await get(.relatedTracks(id, limit))
    }

    // MARK: - Search 🕵️
    /// Search for tracks.
    ///
    /// - Parameters:
    ///   - query: Free-text search query.
    ///   - limit: Page size (default 20).
    /// - Returns: A paginated `Page<Track>`. Use `page.nextHref` with `nextPage(from:)` to load more.
    /// - Throws: Authorization, network, or decoding errors.
    func searchTracks(matching query: String, limit: Int = 20) async throws -> Page<Track> {
        try await get(.searchTracks(query, limit))
    }
    
    /// Search for playlists.
    ///
    /// - Parameters:
    ///   - query: Free-text search query.
    ///   - limit: Page size (default 20).
    /// - Returns: A paginated `Page<Playlist>`. Use `page.nextHref` with `nextPage(from:)` to load more.
    /// - Throws: Authorization, network, or decoding errors.
    func searchPlaylists(matching query: String, limit: Int = 20) async throws -> Page<Playlist> {
        try await get(.searchPlaylists(query, limit))
    }
    
    /// Search for users.
    ///
    /// - Parameters:
    ///   - query: Free-text search query.
    ///   - limit: Page size (default 20).
    /// - Returns: A paginated `Page<User>`. Use `page.nextHref` with `nextPage(from:)` to load more.
    /// - Throws: Authorization, network, or decoding errors.
    func searchUsers(matching query: String, limit: Int = 20) async throws -> Page<User> {
        try await get(.searchUsers(query, limit))
    }

    // MARK: - Like + Follow 🧡
    /// Like a track on behalf of the authenticated user.
    ///
    /// - Parameter track: The track to like.
    /// - Throws: Authorization or network errors.
    /// - Warning: The liked track may not immediately appear in `likedTracks()` since
    ///   the API may cache responses. Consider also tracking liked tracks locally.
    func like(_ track: Track) async throws {
        try await get(.likeTrack(track.id))
    }
    
    /// Remove a track from your likes.
    ///
    /// - Parameter track: The track to unlike.
    /// - Throws: Authorization or network errors.
    func unlike(_ track: Track) async throws {
        try await get(.unlikeTrack(track.id))
    }
    
    /// Like a playlist on behalf of the authenticated user.
    ///
    /// - Parameter playlist: The playlist to like.
    /// - Throws: Authorization or network errors.
    func like(_ playlist: Playlist) async throws {
        try await get(.likePlaylist(playlist.id))
    }
    
    /// Remove a playlist from your likes.
    ///
    /// - Parameter playlist: The playlist to unlike.
    /// - Throws: Authorization or network errors.
    func unlike(_ playlist: Playlist) async throws {
        try await get(.unlikePlaylist(playlist.id))
    }
    
    /// Follow a user on behalf of the authenticated account.
    ///
    /// - Parameter user: The user to follow.
    /// - Throws: Authorization or network errors.
    func follow(_ user: User) async throws {
        try await get(.followUser(user.id))
    }
    
    /// Unfollow a user on behalf of the authenticated account.
    ///
    /// - Parameter user: The user to unfollow.
    /// - Throws: Authorization or network errors.
    func unfollow(_ user: User) async throws {
        try await get(.unfollowUser(user.id))
    }

    // MARK: - Miscellaneous ✨
    
    /// Resolve a SoundCloud web URL to its canonical API resource.
    ///
    /// Use this to turn a user-facing SoundCloud URL (e.g., `https://soundcloud.com/...` or
    /// `https://on.soundcloud.com/...`) into a strongly-typed API model such as `Track`,
    /// `Playlist`, or `User`.
    ///
    /// The generic `ItemType` you choose must match the resource type the URL resolves to.
    ///
    /// - Parameter url: A full SoundCloud URL to resolve.
    /// - Returns: The decoded resource of the specified type.
    /// - Throws: The same errors as other API calls, including authorization, network, and decoding failures.
    ///
    /// ### Examples
    /// ```swift
    /// // Track
    /// let track: Track = try await sc.resolve("https://soundcloud.com/user/track-permalink")
    ///
    /// // Playlist
    /// let playlist: Playlist = try await sc.resolve("https://soundcloud.com/user/sets/my-set")
    ///
    /// // User
    /// let user: User = try await sc.resolve("https://soundcloud.com/username")
    /// ```
    func resolve<ItemType: Decodable>(_ url: String) async throws -> ItemType {
        try await get(.resolve(url))
    }
    
    /// Fetch the next page of results.
    ///
    /// Pass the `nextHref` from an existing `Page<T>` to continue pagination.
    /// - Parameter href: The `nextHref` URL from a previous page.
    /// - Returns: The next `Page` of items.
    /// - Throws: Authorization, network, or decoding errors.
    func nextPage<ItemType>(from href: String) async throws -> Page<ItemType> {
        try await get(.getNextPage(href))
    }
    
    /// Fetch stream information for a track.
    ///
    /// Use this to obtain stream URLs and playback-related metadata.
    /// - Parameter id: The track URN.
    /// - Returns: `StreamInfo` suitable for initiating playback.
    /// - Throws: Authorization, network, or decoding errors.
    func streamInfo(for id: URN) async throws -> StreamInfo {
        try await get(.streamInfoForTrack(id))
    }
    
    /// Handle a notification carrying newly issued OAuth tokens.
    ///
    /// Expects `notification.object` to be `Data` representing a `TokenResponse`.
    /// - Parameter notification: A notification whose `object` contains encoded token data.
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
            request.allHTTPHeaderFields = try await authorizationHeader // Will refresh tokens if necessary
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
        log("💾 Current access token: \(token ?? "None")")
    }
    
    func logNewAuthToken(_ token: String) {
        log("🌟 Received new access token: \(token)")
    }
}
