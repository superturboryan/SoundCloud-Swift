//
//  Test Models.swift
//  WatchCloud
//
//  Created by Ryan Forsyth on 2023-10-03.
//

public func testUser(_ id: Int = Int.random(in: 0..<1000)) -> User {
    User(
        avatarUrl: "https://i1.sndcdn.com/avatars-0DxRBnyCNCI3zL1X-oeoRyw-large.jpg",
        id: id,
        permalinkUrl: "https://i1.sndcdn.com/avatars-0DxRBnyCNCI3zL1X-oeoRyw-large.jpg",
        uri: "",
        username: "RIZ LA TEEF",
        createdAt: "",
        firstName: "",
        lastName: "",
        fullName: "",
        city: "Angel LDN",
        country: "",
        description: """
        DJ

        Always looking to cut dubplates and promote new tunes/producers, so feel free to send me tunes on here or to rizlateef111@gmail.com

        Bookings: nikki@synchronicity.agency

        Label: @southlondonpressings
        """,
        trackCount: 67,
        repostsCount: 0,
        followersCount: 2673,
        followingsCount: 0,
        commentsCount: 0,
        online: false,
        likesCount: 0,
        playlistCount: 0,
        subscriptions: [testNextProSubscription]
    )
}

public func testPlaylist(empty: Bool = false) -> Playlist {
    Playlist (
        id: Int.random(in: 0..<1000),
        genre: "",
        permalink: "",
        permalinkUrl: "https://google.com",
        description: nil,
        uri: "",
        tagList: "",
        trackCount: 7,
        lastModified: "023/08/10 20:27:42 +0000",
        license: "",
        user: testUser(),
        likesCount: 20,
        sharing: "",
        createdAt: "2023/03/20 17:08:42 +0000",
        tags: "",
        kind: "",
        title: "RIZ LA TEEF on Rinse FM",
        streamable: true,
        artworkUrl: testTrack().artworkUrl,
        tracksUri: "https://api.soundcloud.com/playlists/1587600994/tracks",
        tracks: empty ? [] : [testTrack(), testTrack(), testTrack(), testTrack(), testTrack()]
    )
}

public func testTrack(isLiked: Bool = false) -> Track {
    Track(
        id: Int.random(in: 0..<1000),
        createdAt: "2023/08/08 08:24:13 +0000",
        duration: 3678067,
        commentCount: 0,
        sharing: "public",
        tagList: "FrazerRay RinseFM Breakbeat Garage Bass",
        streamable: true,
        genre: "",
        title: "Frazer Ray - 07 August 2023",
        description: "",
        license: "",
        uri: "https://api.soundcloud.com/tracks/1586682955",
        user: testUser(),
        permalinkUrl: "https://soundcloud.com",
        artworkUrl: "https://i1.sndcdn.com/artworks-5Ahdjl0532u9N1a2-zoAq3w-large.jpg",
        streamUrl: "https://api.soundcloud.com/tracks/1586682955/stream",
        downloadUrl: "",
        waveformUrl: "https://wave.sndcdn.com/ycxIIzLADTvQ_m.png",
        availableCountryCodes: ["ca"],
        userFavorite: isLiked,
        userPlaybackCount: 0,
        playbackCount: 0,
        favoritingsCount: 0,
        repostsCount: 0,
        access: "playable"
    )
}

public var testDefaultLoadedPlaylists: [Int : Playlist] {
    var loadedPlaylists = [Int : Playlist]()
    let user = testUser()
    loadedPlaylists[PlaylistType.nowPlaying.rawValue] = Playlist(id: PlaylistType.nowPlaying.rawValue, user: user, title: PlaylistType.nowPlaying.title, tracks: [])
    loadedPlaylists[PlaylistType.downloads.rawValue] = Playlist(id: PlaylistType.downloads.rawValue, user: user, title: PlaylistType.downloads.title, tracks: [])
    loadedPlaylists[PlaylistType.likes.rawValue] = Playlist(id: PlaylistType.likes.rawValue, permalinkUrl: user.permalinkUrl + "/likes", user: user, title: PlaylistType.likes.title, tracks: [])
    loadedPlaylists[PlaylistType.recentlyPosted.rawValue] = Playlist(id: PlaylistType.recentlyPosted.rawValue, permalinkUrl: user.permalinkUrl + "/following", user: user, title: PlaylistType.recentlyPosted.title, tracks: [])
    return loadedPlaylists
}

public let testFreeSubscription = User.Subscription(product: User.Subscription.Product(id: "free", name: "Free"))
public let testNextProSubscription = User.Subscription(product: User.Subscription.Product(id: "next_pro", name: "Next Pro"))

public var testSC = SoundCloud(SoundCloud.Config(clientId: "", clientSecret: "", redirectURI: ""))

public let testStreamInfo = StreamInfo(httpMp3128URL: "", hlsMp3128URL: "")
