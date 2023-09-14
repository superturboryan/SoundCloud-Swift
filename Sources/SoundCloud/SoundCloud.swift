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
    
    // TODO: Make all @Published use private(set)
    @Published public var myUser: User? = nil
    @Published public private(set) var isLoggedIn: Bool = true // Prevents LoginView from appearing every app load
    
    @Published public var loadedPlaylists: [Int : Playlist] = [:]
    @Published public private(set) var loadedTrackNowPlayingQueueIndex: Int = -1
    @Published public var loadedTrack: Track? {
        didSet {
            loadedTrackNowPlayingQueueIndex = loadedPlaylists[PlaylistType.nowPlaying.rawValue]?
                .tracks?
                .firstIndex(where: { $0 == loadedTrack }) ?? -1
        }
    }
    
    @Published public var downloadsInProgress: [Track : Progress] = [:]
    @Published public var downloadedTracks: [Track] = [] { // Tracks with streamURL set to local mp3 url
        didSet {
            loadedPlaylists[PlaylistType.downloads.rawValue]!.tracks = downloadedTracks
        }
    }
    
    public var isLoadedTrackDownloaded: Bool {
        guard let loadedTrack else { return false }
        return downloadedTracks.contains(loadedTrack)
    }
    
    // Use id to filter loadedPlaylists dictionary for my + liked playlists
    public var myPlaylistIds: [Int] = []
    public var myLikedPlaylistIds: [Int] = []
    
    private var downloadTasks: [Track : URLSessionTask] = [:]
    
    private var tokenPersistenceService: AuthTokenPersisting
    private var authTokens: OAuthTokenResponse? {
        get { tokenPersistenceService.authTokens }
        set {
            if let newValue {
                tokenPersistenceService.save(newValue)
                print("✅ 💾 🔑 New tokens saved to persistence")
            } else {
                tokenPersistenceService.delete()
            }
        }
    }
    
    public var authHeader: [String : String] { get async throws {
        guard let authTokens
        else { throw Error.userNotAuthorized }
        
        if authTokens.isExpired {
            print("⚠️ Auth tokens expired at: \(authTokens.expiryDate!)")
            try await refreshAuthTokens()
        }
        return ["Authorization" : "Bearer " + (authTokens.accessToken)]
    }}
    
    private let decoder = JSONDecoder()
    private var subscriptions = Set<AnyCancellable>()
    
    // TODO: Bundle in a config object?
    private let apiURL: String
    private let clientId: String
    private let clientSecret: String
    private let redirectURI: String
        
    /// Use this initializer to optionally inject persistence  service to use when interacting with the SoundCloud API.
    ///
    /// If you need to assign the SC instance to a **SwiftUI ObservableObject** variable, you can use a closure to inject
    /// the dependencies and then return the SC instance:
    /// ```swift
    /// @StateObject var sc: SC = { () -> SC in
    ///    let dependency = KeychainService()
    ///    return SC(tokenService: dependency)
    /// }() // 👀 Don't forget to execute the closure!
    /// ```
    ///  - Parameter apiURL: Base URL to use for API requests. **Defaults to http://api.soundcloud.com**
    ///  - Parameter clientID: Client ID to use when authorizing with API and requesting tokens.
    ///  - Parameter clientSecret: Client secret to use when authorizing with API and requesting tokens.
    ///  - Parameter redirectURI: URI to use when redirecting from OAuth login page to app. This URI should take the form
    ///  `(app URLScheme)://(callback path)`.
    ///  - Parameter tokenService: Serivce to use for persisting OAuthTokens. **Defaults to Keychain**
    public init(
        apiURL: String = "https://api.soundcloud.com/",
        clientId: String,
        clientSecret: String,
        redirectURI: String,
        tokenPersistenceService: AuthTokenPersisting = KeychainService()
    ) {
        self.tokenPersistenceService = tokenPersistenceService
        self.apiURL = apiURL
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectURI = redirectURI
        super.init()
        
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        if let authTokens { print("✅💾🔐 SC.init: Loaded saved auth tokens: \(authTokens.accessToken)") }
    }
}

// MARK: - Public API
public extension SoundCloud {
    func login() async {
        //TODO: Handle try! errors
        do {
            let authCode = try await getAuthCode()
            let newAuthTokens = try await getNewAuthTokens(using: authCode)
            authTokens = newAuthTokens
            isLoggedIn = true
        } catch {
            print("❌ 🔊 ☁️ SC.login: \(error.localizedDescription)")
        }
    }
    
    func logout() {
        authTokens = nil
        isLoggedIn = false
    }
    
    func loadLibrary() async throws {
        
        try await loadMyProfile()
        loadDefaultPlaylists() // ⚠️ Must call loadMyProfile first!
        try loadDownloadedTracks()
        
        try? await loadMyPlaylistsWithoutTracks()
        try? await loadMyLikedPlaylistsWithoutTracks()
        try? await loadMyLikedTracksPlaylistWithTracks()
        try? await loadRecentlyPostedPlaylistWithTracks()
    }
    
    func loadMyProfile() async throws {
        myUser = try await get(.me())
    }
    
    func loadMyLikedTracksPlaylistWithTracks() async throws {
        loadedPlaylists[PlaylistType.likes.rawValue]?.tracks = try await get(.myLikedTracks())
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
    
    func download(_ track: Track) async throws {
        let streamInfo = try await getStreamInfoForTrack(with: track.id)
        try await downloadTrack(track, from: streamInfo.httpMp3128Url)
    }
     
    func removeDownload(_ trackToRemove: Track) throws {
        let trackMp3Url = trackToRemove.localFileUrl(withExtension: Track.FileExtension.mp3)
        let trackJsonUrl = trackToRemove.localFileUrl(withExtension: Track.FileExtension.json)
        try FileManager.default.removeItem(at: trackMp3Url)
        try FileManager.default.removeItem(at: trackJsonUrl)
        
        downloadedTracks.removeAll(where: { $0.id == trackToRemove.id })
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
        loadedPlaylists[PlaylistType.nowPlaying.rawValue]!.tracks
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
        let authorizeURL = apiURL
        + "connect"
        + "?client_id=\(clientId)"
        + "&redirect_uri=\(redirectURI)"
        + "&response_type=code"
        
        #if os(iOS)
        return try await ASWebAuthenticationSession.getAuthCode(
            from: authorizeURL,
            with: redirectURI,
            ephemeralSession: false
        )
        #else
        return try await ASWebAuthenticationSession.getAuthCode(
            from: authorizeURL,
            with: redirectURI
        )
        #endif
    }
    
    private func getNewAuthTokens(using authCode: String) async throws -> (OAuthTokenResponse) {
        let tokenResponse = try await get(.accessToken(authCode, clientId, clientSecret, redirectURI))
        print("✅ Received new tokens:"); dump(tokenResponse)
        return tokenResponse
    }
    
    private func refreshAuthTokens() async throws {
        let tokenResponse = try await get(.refreshToken(authTokens!.refreshToken, clientId, clientSecret, redirectURI))
        print("♻️ Refreshed tokens:"); dump(tokenResponse)
        authTokens = tokenResponse
    }
}

// MARK: - API request
private extension SoundCloud {
    
    @discardableResult
    func get<T: Decodable>(_ request: Request<T>) async throws -> T {
        try await fetchData(from: authorized(request))
    }
    
    func fetchData<T: Decodable>(from request: URLRequest) async throws -> T {
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCodeInt = (response as! HTTPURLResponse).statusCode
        let statusCode = StatusCode(rawValue: statusCodeInt)!
        
        if statusCode == .unauthorized { throw Error.userNotAuthorized }
        else if statusCode.errorOccurred { throw Error.networkError(statusCode) }
        else {
            let decodedObject = try decoder.decode(T.self, from: data)
            return decodedObject
        }
    }
    
    func authorized<T>(_ scRequest: Request<T>) async throws -> URLRequest {
        let urlWithPath = URL(string: apiURL + scRequest.path)!
        var components = URLComponents(url: urlWithPath, resolvingAgainstBaseURL: false)!
        components.queryItems = scRequest.queryParameters?.map { URLQueryItem(name: $0, value: $1) }
        
        var request = URLRequest(url: components.url!)
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
        let localMp3Url = track.localFileUrl(withExtension: Track.FileExtension.mp3)
        
        // Checks before starting download
        let localFileDoesNotExist = !FileManager.default.fileExists(atPath: localMp3Url.path)
        let downloadNotAlreadyInProgress = !downloadsInProgress.keys.contains(track)
        guard localFileDoesNotExist, downloadNotAlreadyInProgress
        else {
            //TODO: Throw error?
            print("😳 Track already exists or is being downloaded!")
            return
        }
        
        // Set empty progress for track so didCreateTask can know which track it's starting download for
        downloadsInProgress[track] = Progress(totalUnitCount: 0)
        
        var request = URLRequest(url: URL(string: url)!)
        request.allHTTPHeaderFields = try await authHeader
        
        // ‼️ Response does not contain ID for track (only encrypted ID)
        // Add track ID to request header to know which track is being downloaded in delegate
        request.addValue("\(track.id)", forHTTPHeaderField: "track_id")
        
        //TODO: Catch errors, check response
        let (trackData, _) = try await URLSession.shared.data(for: request, delegate: self)
        downloadsInProgress.removeValue(forKey: track)
        
        try trackData.write(to: localMp3Url)
        let trackJsonData = try JSONEncoder().encode(track)
        let localJsonUrl = track.localFileUrl(withExtension: Track.FileExtension.json)
        try trackJsonData.write(to: localJsonUrl)
        
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
    
    public func removeDownloadInProgress(for track: Track) throws {
        guard
            downloadsInProgress.keys.contains(track),
            let task = downloadTasks[track]
        else { throw Error.trackDownloadNotInProgress }
        
        downloadsInProgress.removeValue(forKey: track)
        task.cancel()
        downloadTasks.removeValue(forKey: track)
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
