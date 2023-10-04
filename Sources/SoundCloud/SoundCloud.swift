//
//  SC.swift
//  SoundCloud
//
//  Created by Ryan Forsyth on 2023-08-10.
//

import AuthenticationServices
import Combine
import SwiftUI

@MainActor
final public class SoundCloud: NSObject, ObservableObject {
    
    @Published public var myUser: User? = nil
    @Published public private(set) var isLoggedIn: Bool = true
    
    @Published public var loadedPlaylists: [Int : Playlist] = [:]
    @Published public private(set) var loadedTrackNowPlayingQueueIndex: Int = -1
    @Published public var loadedTrack: Track? {
        didSet {
            loadedTrackNowPlayingQueueIndex = loadedPlaylists[PlaylistType.nowPlaying.rawValue]?
                .tracks?
                .firstIndex(where: { $0 == loadedTrack }) ?? -1
        }
    }
    
    @Published public var usersImFollowing: Page<User>? = nil
    
    @Published public var downloadsInProgress: [Track : Progress] = [:]
    @Published public var downloadedTracks: [Track] = [] { // Tracks with streamURL set to local mp3 url
        didSet {
            loadedPlaylists[PlaylistType.downloads.rawValue]!.tracks = downloadedTracks
        }
    }
    
    // Use id to filter loadedPlaylists dictionary for my + liked playlists
    public var myPlaylistIds: [Int] = []
    public var myLikedPlaylistIds: [Int] = []
    
    private var downloadTasks: [Track : URLSessionTask] = [:]
    
    private let tokenPersistenceService = KeychainService<TokenResponse>("OAuthTokenResponse")
    private let userPersistenceService = UserDefaultsService<User>("\(User.self)")
    
    public var isLoadedTrackDownloaded: Bool {
        guard let loadedTrack else { return false }
        return downloadedTracks.contains(loadedTrack)
    }
    
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
    
    private let decoder = JSONDecoder()
    private var subscriptions = Set<AnyCancellable>()
    
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

// MARK: - Public API
public extension SoundCloud {
    func login() async throws {
        do {
            let authCode = try await getAuthCode()
            let newAuthTokens = try await getNewAuthTokens(using: authCode)
            persistAuthTokensWithCreationDate(newAuthTokens)
            isLoggedIn = true
        } catch(ASWebAuthenticationSession.Error.cancelledLogin) {
            // Do nothing in this case
        } catch {
            throw Error.loggingIn
        }
    }
    
    func logout() {
        tokenPersistenceService.delete()
        userPersistenceService.delete()
        isLoggedIn = false
    }
    
    func loadLibrary() async throws {
        
        try await loadMyProfile()
        loadDefaultPlaylists() // ⚠️ Must call loadMyProfile first!
        try loadDownloadedTracks()
        
        try await loadMyPlaylistsWithoutTracks()
        try await loadMyLikedPlaylistsWithoutTracks()
        try await loadMyLikedTracksPlaylistWithTracks()
        try await loadRecentlyPostedPlaylistWithTracks()
        
        try await loadUsersImFollowing()
    }
    
    func loadMyProfile() async throws {
        if let savedUser = userPersistenceService.get() {
            myUser = savedUser
        } else {
            let loadedUser = try await get(.me())
            myUser = loadedUser
            userPersistenceService.save(loadedUser)
        }
    }
    
    func loadMyLikedTracksPlaylistWithTracks() async throws {
        let response = try await get(.myLikedTracks())
        loadedPlaylists[PlaylistType.likes.rawValue]?.tracks = response.items
        loadedPlaylists[PlaylistType.likes.rawValue]?.nextPageUrl = response.nextPage
    }
    
    func loadNextPageOfTracksForPlaylist(_ playlist: Playlist) async throws {
        let response: Page<Track> = try await get(.collectionForHref(playlist.nextPageUrl ?? ""))
        loadedPlaylists[playlist.id]?.tracks! += response.items
        loadedPlaylists[playlist.id]?.nextPageUrl = response.nextPage
    }
    
    func loadRecentlyPostedPlaylistWithTracks() async throws {
        loadedPlaylists[PlaylistType.recentlyPosted.rawValue]?.tracks = try await get(.myFollowingsRecentlyPosted())
    }
    
    func loadMyLikedPlaylistsWithoutTracks() async throws {
        let myLikedPlaylists = try await get(.myLikedPlaylists())
        myLikedPlaylistIds = myLikedPlaylists.map(\.id)
        for playlist in myLikedPlaylists {
            loadedPlaylists[playlist.id] = playlist
        }
    }
    
    func loadMyPlaylistsWithoutTracks() async throws {
        let myPlaylists = try await get(.myPlaylists())
        myPlaylistIds = myPlaylists.map(\.id)
        for playlist in myPlaylists {
            loadedPlaylists[playlist.id] = playlist
        }
    }
    
    func loadTracksForPlaylist(with id: Int) async throws {
        if let userPlaylistType = PlaylistType(rawValue: id) {
            switch userPlaylistType {
            case .likes:
                try await loadMyLikedTracksPlaylistWithTracks()
            case .recentlyPosted:
                try await loadRecentlyPostedPlaylistWithTracks()
            // These playlists are not reloaded here
            case .nowPlaying, .downloads:
                print("⚠️ SC.loadTracksForPlaylist has no effect. Playlist type reloads automatically")
                break
            }
        } else {
            loadedPlaylists[id]?.tracks = try await getTracksForPlaylist(with: id)
        }
    }
    
    func loadUsersImFollowing() async throws {
        if usersImFollowing == nil {
            let response = try await get(.usersImFollowing())
            usersImFollowing = response
        } else {
            let response: Page<User> = try await get(.collectionForHref(usersImFollowing?.nextPage ?? ""))
            usersImFollowing?.items += response.items
            usersImFollowing?.nextPage = response.nextPage
        }
    }
    
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
    
    func likeTrack(_ likedTrack: Track) async throws {
        try await get(.likeTrack(likedTrack.id))
        // 🚨 Hack for SC API cached responses -> Update loaded playlist manually
        loadedPlaylists[PlaylistType.likes.rawValue]?.tracks?.insert(likedTrack, at: 0)
    }
    
    func unlikeTrack(_ unlikedTrack: Track) async throws {
        try await get(.unlikeTrack(unlikedTrack.id))
        // 🚨 Hack for SC API cached responses -> Update loaded playlist manually
        loadedPlaylists[PlaylistType.likes.rawValue]?.tracks?.removeAll(where: { $0.id == unlikedTrack.id })
    }
    
    func getTracksForUser(_ id: Int, _ limit: Int = 20) async throws -> Page<Track> {
        try await get(.tracksForUser(id, limit))
    }

    func getLikedTracksForUser(_ id: Int, _ limit: Int = 20) async throws -> Page<Track> {
        try await get(.likedTracksForUser(id, limit))
    }

    func followUser(_ user: User) async throws {
        #warning("Investigate behaviour when following user twice in a row")
        try await get(.followUser(user.id))
        usersImFollowing?.items.insert(user, at: 0)
    }

    func unfollowUser(_ user: User) async throws {
        try await get(.unfollowUser(user.id))
        usersImFollowing?.items.removeAll(where: { $0 == user })
    }

    // MARK: - Private API Helpers
    private func getTracksForPlaylist(with id: Int) async throws -> [Track] {
        try await get(.tracksForPlaylist(id))
    }
    
    private func getStreamInfoForTrack(with id: Int) async throws -> StreamInfo {
        try await get(.streamInfoForTrack(id))
    }
    
    private func loadDefaultPlaylists() {
        loadedPlaylists.removeAll()
        
        loadedPlaylists[PlaylistType.nowPlaying.rawValue] = Playlist(
            id: PlaylistType.nowPlaying.rawValue,
            user: myUser!,
            title: PlaylistType.nowPlaying.title,
            tracks: []
        )
        loadedPlaylists[PlaylistType.downloads.rawValue] = Playlist(
            id: PlaylistType.downloads.rawValue,
            user: myUser!,
            title: PlaylistType.downloads.title,
            tracks: []
        )
        loadedPlaylists[PlaylistType.likes.rawValue] = Playlist(
            id: PlaylistType.likes.rawValue,
            permalinkUrl: myUser!.permalinkUrl + "/likes",
            user: myUser!,
            title: PlaylistType.likes.title,
            tracks: []
        )
        loadedPlaylists[PlaylistType.recentlyPosted.rawValue] = Playlist(
            id: PlaylistType.recentlyPosted.rawValue,
            permalinkUrl: myUser!.permalinkUrl + "/following",
            user: myUser!,
            title: PlaylistType.recentlyPosted.title,
            tracks: []
        )
    }
}

// MARK: - Queue helpers
public extension SoundCloud {
    func setNowPlayingQueue(with tracks: [Track]) {
        loadedPlaylists[PlaylistType.nowPlaying.rawValue]?.tracks = tracks
    }
    
    var nowPlayingQueue: [Track]? {
        loadedPlaylists[PlaylistType.nowPlaying.rawValue]?.tracks
    }
    
    var nextTrackInNowPlayingQueue: Track? {
        guard let queue = nowPlayingQueue
        else { return nil }
        
        let isEndOfQueue = loadedTrackNowPlayingQueueIndex == queue.count - 1
        let nextTrackIndex = isEndOfQueue ? 0 : loadedTrackNowPlayingQueueIndex + 1
        return queue[nextTrackIndex]
    }
    
    var previousTrackInNowPlayingQueue: Track? {
        guard let queue = nowPlayingQueue,
              loadedTrackNowPlayingQueueIndex > 0
        else { return nil }
        
        let previousTrackIndex = loadedTrackNowPlayingQueueIndex - 1
        return queue[previousTrackIndex]
    }
}

// MARK: - Authentication
extension SoundCloud {
    private func getAuthCode() async throws -> String {
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
    
    private func getNewAuthTokens(using authCode: String) async throws -> (TokenResponse) {
        let tokenResponse = try await get(.accessToken(authCode, config.clientId, config.clientSecret, config.redirectURI))
        print("✅ Received new tokens:"); dump(tokenResponse)
        return tokenResponse
    }
    
    private func refreshAuthTokens() async throws {
        let persistedRefreshToken = tokenPersistenceService.get()?.refreshToken ?? ""
        let newTokens = try await get(.refreshToken(persistedRefreshToken, config.clientId, config.clientSecret, config.redirectURI))
        print("♻️ Refreshed tokens:"); dump(newTokens)
        persistAuthTokensWithCreationDate(newTokens)
    }
    
    private func persistAuthTokensWithCreationDate(_ tokens: TokenResponse) {
        var tokensWithDate = tokens
        tokensWithDate.expiryDate = tokens.expiresIn.dateWithSecondsAdded(to: Date())
        tokenPersistenceService.save(tokensWithDate)
    }
}

// MARK: - API request
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
extension SoundCloud: URLSessionTaskDelegate {
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
    
    public func cancelDownloadInProgress(for track: Track) throws {
        guard downloadsInProgress.keys.contains(track), let task = downloadTasks[track] else {
            throw Error.trackDownloadNotInProgress
        }
        task.cancel()
        downloadTasks.removeValue(forKey: track)
        downloadsInProgress.removeValue(forKey: track)
    }
    
    private func loadDownloadedTracks() throws {
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
