//
//  SoundCloudAuthentication.swift
//  SC Demo
//
//  Created by Ryan Forsyth on 2023-08-10.
//

import Combine
import Foundation
import AuthenticationServices

@MainActor
public class SC: NSObject, ObservableObject {
    
    @Published public var me: Me? = nil
    @Published public private(set) var isLoggedIn: Bool = true
    
    @Published public var downloadsInProgress: [Track : Double] = [:]
    
    @Published public var downloadedTracks: [Track] = []
    
    private var authPersistenceService: AuthTokenPersisting
    
    public var authTokens: OAuthTokenResponse? {
        get {
            authPersistenceService.loadAuthTokens()
        }
        set {
            isLoggedIn = newValue != nil
            if let newValue {
                authPersistenceService.saveAuthTokens(newValue)
                print("✅ 💾 🔑 Tokens saved to persistence")
            } else {
                authPersistenceService.deleteAuthTokens()
            }
        }
    }
    
    private let decoder = JSONDecoder()
    
    private var authHeader: [String : String] {
        ["Authorization" : "Bearer " + (authTokens?.accessToken ?? "")]
    }
    
    private var subscriptions = Set<AnyCancellable>()
    
    /// Use this initializer to optionally inject persistence  service to use when interacting with the SoundCloud API.
    ///
    /// If you need to assign the SC instance to a **SwiftUI ObservableObject** variable, you can use a closure to inject
    /// the dependencies and then return the SC instance:
    /// ```swift
    /// @StateObject var sc: SC = { () -> SC in
    ///    let dependency = KeychainService()
    ///    return SC(authPersistenceService: dependency)
    /// }() // Don't forget to execute the closure!
    /// ```
    ///  - Parameter authPersistenceService: Serivce to use for persisting OAuthTokens. **Defaults to Keychain**
    public init(
        authPersistenceService: AuthTokenPersisting = KeychainService()
    ) {
        self.authPersistenceService = authPersistenceService
        super.init()
        
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        if authTokens == nil { 
            logout()
        } else {
            print("✅ 💾 🔑 Loaded tokens from persistence")
            dump(authTokens)
        }
        
        try? loadDownloadedTracks()
    }
}

//MARK: - API
public extension SC {
    func login() async {
        //TODO: Handle try! errors
        do {
            let authCode = try await getAuthCode()
            print("✅ 🔊 ☁️")
            let newAuthTokens = try await getNewAuthTokens(using: authCode)
            authTokens = newAuthTokens
        } catch {
            print("❌ 🔊 ☁️ \(error.localizedDescription)")
        }
    }
    
    func logout() {
        authTokens = nil
    }
    
    func loadMyProfile() async throws {
        me = try await get(.me())
    }
    
    func getMyLikedTracks() async throws -> Playlist {
        let tracks = try await get(.myLikedTracks())
        return Playlist(
            id: UserPlaylistId.likes.rawValue,
            genre: "",
            permalink: "",
            permalinkUrl: "",
            description: "",
            uri: "",
            tagList: "",
            trackCount: tracks.count,
            lastModified: "",
            license: "",
            user: me!.user,
            likesCount: 0,
            sharing: "",
            createdAt: "",
            tags: "",
            kind: "",
            title: "Likes",
            streamable: true,
            artworkUrl: tracks.first?.artworkUrl ?? "",
            tracksUri: "",
            tracks: tracks
        )
    }
    
    func getMyFollowingsRecentTracks() async throws -> Playlist {
        let tracks = try await get(.myFollowingsRecentTracks())
        return Playlist(
            id: UserPlaylistId.myFollowingsRecentTracks.rawValue,
            genre: "",
            permalink: "",
            permalinkUrl: "",
            description: "",
            uri: "",
            tagList: "",
            trackCount: tracks.count,
            lastModified: "",
            license: "",
            user: me!.user,
            likesCount: 0,
            sharing: "",
            createdAt: "",
            tags: "",
            kind: "",
            title: "Recently posted",
            streamable: true,
            artworkUrl: tracks.first!.artworkUrl,
            tracksUri: "",
            tracks: tracks
        )
    }
    
    func getMyLikedPlaylists() async throws -> [Playlist] {
        let playlists = try await get(.myLikedPlaylists())
        let playlistsWithTracks = try await withThrowingTaskGroup(of: (Playlist, [Track]).self, returning: [Playlist].self) { taskGroup in
            for playlist in playlists {
                taskGroup.addTask { (playlist, try await self.getTracksForPlaylists(playlist.id)) }
            }
            
            var result = [Playlist]()
            for try await (playlist, tracks) in taskGroup {
                var playlistWithTracks = playlist
                playlistWithTracks.tracks = tracks
                result.append(playlistWithTracks)
            }
            
            return result
        }
        
        return playlistsWithTracks
    }
    
    func getMyPlaylists() async throws -> [Playlist] {
        try await get(.myPlaylists())
    }
    
    private func getTracksForPlaylists(_ id: Int) async throws -> [Track] {
        try await get(.tracksForPlaylist(id))
    }
    
    private func getStreamInfoForTrack(_ id: Int) async throws -> StreamInfo {
        try await get(.streamInfoForTrack(id))
    }
    
    func beginDownloadingTrack(_ track: Track) async throws {
        let streamInfo = try await getStreamInfoForTrack(track.id)
        try await beginDownloadingTrack(track, from: streamInfo.httpMp3128Url)
    }
    
    func getDownloadedTracks() throws -> [Track] {
        
        
        return []
    }
}

//MARK: - Authentication
extension SC {
    private func getAuthCode() async throws -> String {
        #if os(iOS)
        try await ASWebAuthenticationSession.getAuthCode(
            from: authorizeURL,
            ephemeralSession: false
        )
        #else
        try await ASWebAuthenticationSession.getAuthCode(
            from: authorizeURL
        )
        #endif
    }
    
    private func getNewAuthTokens(using authCode: String) async throws -> (OAuthTokenResponse) {
        let tokenResponse = try await get(.accessToken(authCode))
        print("✅ Received new tokens:")
        dump(tokenResponse)
        return tokenResponse
    }
    
    public func refreshAuthTokens() async throws {
        let tokenResponse = try await get(.refreshToken(authTokens?.refreshToken ?? ""))
        print("♻️  Refreshed tokens:")
        dump(tokenResponse)
        authTokens = tokenResponse
    }
}

// MARK: - API request
extension SC {
    private func get<T: Decodable>(_ request: Request<T>) async throws -> T {
        // ⚠️ Check that this isn't a request to refresh the token
        if authTokens?.isExpired ?? false && isLoggedIn && !request.isToRefresh {
            try await refreshAuthTokens()
        }
        return try await fetchData(from: authorized(request))
    }
    
    private func fetchData<T: Decodable>(from request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        // TODO: Handle response
        let decodedObject = try decoder.decode(T.self, from: data)
        return decodedObject
    }
    
    private func authorized<T>(_ scRequest: Request<T>) -> URLRequest {
        let urlWithPath = URL(string: apiURL + scRequest.path)!
        var components = URLComponents(url: urlWithPath, resolvingAgainstBaseURL: false)!
        components.queryItems = scRequest.queryParameters?.map { URLQueryItem(name: $0, value: $1) }
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = scRequest.httpMethod
        // ⚠️ Don't apply authHeader if access token is being requested
        if scRequest.useAuthHeader {
            request.allHTTPHeaderFields = authHeader
        }
        return request
    }
}

// MARK: - Downloads
extension SC: URLSessionTaskDelegate {
    private func beginDownloadingTrack(_ track: Track, from url: String) async throws {
        
        //TODO: Check if already downloaded!
        let localMp3Url = track.localFileUrl(extensioN: "mp3")
        if FileManager.default.fileExists(atPath: localMp3Url.path) {
            print("😳 Track already exists at path: \(localMp3Url.path)")
            return
        }
        
        downloadsInProgress[track] = 0
        
        var request = URLRequest(url: URL(string: url)!)
        request.allHTTPHeaderFields = authHeader
        // Add track id to request to know which track is being downloaded in delegate
        request.addValue("\(track.id)", forHTTPHeaderField: "track_id")
        
        // Catch error and remove download in progress?
        let (trackData, _) = try await URLSession.shared.data(for: request, delegate: self)
        try trackData.write(to: localMp3Url)
        
        let trackJsonData = try JSONEncoder().encode(track)
        let localJsonUrl = track.localFileUrl(extensioN: "json")
        try trackJsonData.write(to: localJsonUrl)
        
        downloadsInProgress.removeValue(forKey: track)
        
        var trackWithLocalMp3Url = track
        trackWithLocalMp3Url.streamUrl = localMp3Url.absoluteString
        
        downloadedTracks.append(trackWithLocalMp3Url)
    }
    
    public func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        let trackId = (task.originalRequest?.value(forHTTPHeaderField: "track_id"))!
        let trackBeingDownloaded = downloadsInProgress.keys.first(where: {
            $0.id == Int(trackId)
        })!
        task.progress.publisher(for: \.fractionCompleted)
            .receive(on: RunLoop.main)
            .sink { [weak self] progress in
                print("\n⬇️🎵 Download progress for \(trackBeingDownloaded.title): \(progress)")
                self?.downloadsInProgress[trackBeingDownloaded] = progress
            }
            .store(in: &subscriptions)
    }
    
    private func loadDownloadedTracks() throws {
        var loadedTracks = [Track]()
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let downloadedTrackIds = try FileManager.default.contentsOfDirectory(atPath: documentsURL.path).filter {
            // Remove any file not an mp3
            $0.lowercased().contains("mp3")
        }.map {
            // Remove mp3 extension so only id remains
            $0.replacingOccurrences(of: ".mp3", with: "")
        }
        
        for id in downloadedTrackIds {
            let trackJsonURL = documentsURL.appendingPathComponent("\(id).json")
            let trackJsonData = try Data(contentsOf: trackJsonURL)
            var downloadedTrack = try JSONDecoder().decode(Track.self, from: trackJsonData)
            
            let downloadedTrackLocalMp3Url = downloadedTrack.localFileUrl(extensioN: "mp3").absoluteString
            downloadedTrack.streamUrl = downloadedTrackLocalMp3Url
            
            loadedTracks.append(downloadedTrack)
        }
        
        print("\n💾 Loaded downloaded tracks: ")
        dump(downloadedTrackIds)
        
        downloadedTracks = loadedTracks
    }
}

private extension Track {
    func localFileUrl(extensioN: String) -> URL {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsUrl.appendingPathComponent("\(id).\(extensioN)")
    }
}
