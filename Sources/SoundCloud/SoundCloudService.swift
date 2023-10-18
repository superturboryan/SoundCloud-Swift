//
//  SoundCloudService.swift
//  SoundCloud
//
//  Created by Ryan Forsyth on 2023-10-18.
//

import AuthenticationServices
import Combine

final public class SoundCloudService: NSObject {
    
    public var downloadedTracks: [Track] = [] // Tracks with streamURL set to local mp3 url
    public var downloadsInProgress: [Track : Progress] = [:]
    private var downloadTasks: [Track : URLSessionTask] = [:]
    
    private let tokenPersistenceService = KeychainService<TokenResponse>("OAuthTokenResponse")
    
    ///  Returns a dictionary with valid OAuth access token to be used as URLRequest header.
    ///
    ///  **This getter will attempt to refresh the access token first if it is expired**, throwing an error if it fails to refresh the token.
    public var authHeader: [String : String] { get async throws {
        guard let savedAuthTokens = tokenPersistenceService.get() else {
            throw Error.userNotAuthorized
        }
        
        if savedAuthTokens.isExpired {
            print("⚠️ Auth tokens expired at: \(savedAuthTokens.expiryDate != nil ? "\(savedAuthTokens.expiryDate!)" : "Unknown")")
            do {
                try await refreshAuthTokens()
            } catch {
                throw Error.refreshingExpiredAuthTokens
            }
        }
        
        let validAuthTokens = tokenPersistenceService.get()!
        return ["Authorization" : "Bearer " + (validAuthTokens.accessToken)]
    }}
    
    public var isSessionExpired: Bool {
        guard let savedAuthTokens = tokenPersistenceService.get() else {
            return false
        }
        return savedAuthTokens.isExpired
    }
    
    private let decoder = JSONDecoder()
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: - Dependencies
    private let config: SoundCloudConfig
    public init(_ config: SoundCloudConfig) {
        self.config = config
        super.init()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        if let authTokens = tokenPersistenceService.get() {
            print("✅💾🔐 SC.init: Loaded saved auth tokens: \(authTokens.accessToken)")
        }
    }
}

// MARK: - Auth
public extension SoundCloudService {
    func login() async throws {
        do {
            let authCode = try await getAuthCode()
            let newAuthTokens = try await getNewAuthTokens(using: authCode)
            persistAuthTokensWithCreationDate(newAuthTokens)
        } catch(ASWebAuthenticationSession.Error.cancelledLogin) {
            throw Error.cancelledLogin
        } catch {
            throw Error.loggingIn
        }
    }
    
    func logout() {
        tokenPersistenceService.delete()
    }
}

// MARK: - My User
public extension SoundCloudService {
    func getMyUser() async throws -> User {
        try await get(.me())
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

// MARK: - Like + Follow
public extension SoundCloudService {
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

// MARK: - Search
public extension SoundCloudService {
    func searchTracks(_ query: String) async throws -> Page<Track> {
        try await get(.searchTracks(query))
    }
    
    func searchPlaylists(_ query: String) async throws -> Page<Playlist> {
        try await get(.searchPlaylists(query))
    }
    
    func searchUsers(_ query: String) async throws -> Page<User> {
        try await get(.searchUsers(query))
    }
}

// MARK: - Helpers
public extension SoundCloudService {
    func pageOfItems<ItemType>(for href: String) async throws -> Page<ItemType> {
        try await get(.getNextPage(href))
    }

    func getTracksForPlaylist(_ id: Int) async throws -> Page<Track> {
        try await get(.tracksForPlaylist(id))
    }
    
    func getTracksForUser(_ id: Int, _ limit: Int = 20) async throws -> Page<Track> {
        try await get(.tracksForUser(id, limit))
    }
    
    func getLikedTracksForUser(_ id: Int, _ limit: Int = 20) async throws -> Page<Track> {
        try await get(.likedTracksForUser(id, limit))
    }
}

// MARK: - Downloads
public extension SoundCloudService {
    func download(_ track: Track) async throws {
        let streamInfo = try await getStreamInfoForTrack(with: track.id)
        try await downloadTrack(track, from: streamInfo.httpMp3128Url)
    }
    
    func removeDownload(_ trackToRemove: Track) throws {
        let trackMp3Url = trackToRemove.localFileUrl(withExtension: Track.FileExtension.mp3)
        let trackJsonUrl = trackToRemove.localFileUrl(withExtension: Track.FileExtension.json)
        do {
            try FileManager.default.removeItem(at: trackMp3Url)
            try FileManager.default.removeItem(at: trackJsonUrl)
            downloadedTracks.removeAll(where: { $0.id == trackToRemove.id })
        } catch {
            throw Error.removingDownloadedTrack
        }
    }
    
    func cancelDownloadInProgress(for track: Track) throws {
        guard downloadsInProgress.keys.contains(track), let task = downloadTasks[track] else {
            throw Error.trackDownloadNotInProgress
        }
        task.cancel()
        downloadTasks.removeValue(forKey: track)
        downloadsInProgress.removeValue(forKey: track)
    }
    
    private func getStreamInfoForTrack(with id: Int) async throws -> StreamInfo {
        try await get(.streamInfoForTrack(id))
    }
}

// MARK: - Private Auth
private extension SoundCloudService {
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
        print("✅ Received new tokens:"); dump(tokenResponse)
        return tokenResponse
    }
    
    func refreshAuthTokens() async throws {
        let persistedRefreshToken = tokenPersistenceService.get()?.refreshToken ?? ""
        let newTokens = try await get(.refreshToken(persistedRefreshToken, config.clientId, config.clientSecret, config.redirectURI))
        print("♻️ Refreshed tokens:"); dump(newTokens)
        persistAuthTokensWithCreationDate(newTokens)
    }
    
    func persistAuthTokensWithCreationDate(_ tokens: TokenResponse) {
        var tokensWithDate = tokens
        tokensWithDate.expiryDate = tokens.expiresIn.dateWithSecondsAdded(to: Date())
        tokenPersistenceService.save(tokensWithDate)
    }
}

// MARK: - API request
private extension SoundCloudService {
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

// MARK: - Downloads
extension SoundCloudService: URLSessionTaskDelegate {
    private func downloadTrack(_ track: Track, from url: String) async throws {
        // Checks before starting download
        let localMp3Url = track.localFileUrl(withExtension: Track.FileExtension.mp3)
        let localFileDoesNotExist = !FileManager.default.fileExists(atPath: localMp3Url.path)
        let downloadNotAlreadyInProgress = !downloadsInProgress.keys.contains(track)
        guard localFileDoesNotExist, downloadNotAlreadyInProgress else {
            throw Error.downloadAlreadyExists
        }
        // Set empty progress for track so didCreateTask can know which track it's starting download for
        downloadsInProgress[track] = Progress(totalUnitCount: 0)
        // Setup request
        var request = URLRequest(url: URL(string: url)!)
        request.allHTTPHeaderFields = try await authHeader
        // ‼️ Response does not contain ID for track (only encrypted ID)
        // Add track ID to request header to know which track is being downloaded in delegate
        request.addValue("\(track.id)", forHTTPHeaderField: "track_id")
        // Make request for track data
        guard let (trackData, response) = try? await URLSession.shared.data(for: request, delegate: self) else {
            throw Error.noInternet
        }
        let statusCodeInt = (response as! HTTPURLResponse).statusCode
        let statusCode = StatusCode(rawValue: statusCodeInt) ?? .unknown
        guard statusCode != .unauthorized else {
            throw Error.userNotAuthorized
        }
        guard !statusCode.errorOccurred else {
            throw Error.network(statusCode)
        }
        downloadsInProgress.removeValue(forKey: track)
        // Save track data as mp3
        try trackData.write(to: localMp3Url)
        // Save track metadata as track json object
        let trackJsonData = try JSONEncoder().encode(track)
        let localJsonUrl = track.localFileUrl(withExtension: Track.FileExtension.json)
        try trackJsonData.write(to: localJsonUrl)
        // Create copy of track with local file url added
        var trackWithLocalFileUrl = track
        trackWithLocalFileUrl.localFileUrl = localMp3Url.absoluteString
        downloadedTracks.append(trackWithLocalFileUrl)
    }
    
    public func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        // ‼️ Get track id being downloaded from request header field
        guard
            let trackId = Int(task.originalRequest?.value(forHTTPHeaderField: "track_id") ?? ""),
            let trackBeingDownloaded = downloadsInProgress.keys.first(where: { $0.id == trackId })
        else { return }
        // Keep reference to task in case we need to cancel
        downloadTasks[trackBeingDownloaded] = task
        // Assign task's progress to track being downloaded
        task.publisher(for: \.progress)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                DispatchQueue.main.async { // Not sure if this works better than .receive(on:) alone
                    print("\n⬇️🎵 Download progress for \(trackBeingDownloaded.title): \(progress.fractionCompleted)")
                    self?.downloadsInProgress[trackBeingDownloaded] = progress
                }
            }
            .store(in: &subscriptions)
    }
    
    public func loadDownloadedTracks() throws {
        // Get id of downloaded tracks from device's documents directory
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let downloadedTrackIds = try FileManager.default.contentsOfDirectory(atPath: documentsURL.path)
            .filter { $0.lowercased().contains(Track.FileExtension.mp3) } // Get all mp3 files
            .map { $0.replacingOccurrences(of: ".\(Track.FileExtension.mp3)", with: "") } // Remove mp3 extension so only id remains
        
        // Load track for each id, set local mp3 file url for track
        var loadedTracks = [Track]()
        for id in downloadedTrackIds {
            let trackJsonURL = documentsURL.appendingPathComponent("\(id).\(Track.FileExtension.json)")
            let trackJsonData = try Data(contentsOf: trackJsonURL)
            var downloadedTrack = try decoder.decode(Track.self, from: trackJsonData)
            
            let downloadedTrackLocalMp3Url = downloadedTrack.localFileUrl(withExtension: Track.FileExtension.mp3).absoluteString
            downloadedTrack.localFileUrl = downloadedTrackLocalMp3Url
            
            loadedTracks.append(downloadedTrack)
        }
        downloadedTracks = loadedTracks
    }
}
