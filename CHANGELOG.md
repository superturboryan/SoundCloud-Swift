# Changelog

## 🌟 2.0.0

### ⚠️ Warning: Support for version `<2.0.0` has been dropped. The SoundCloud API's way of identifying resources has changed. Please make sure you update to version `2.0.0`. 

See [SoundCloud developer blog post](https://developers.soundcloud.com/blog/urn-num-to-string). 

### ✨ Features
- New **Swiftier** ™️  API
    - Remove all `get-` prefixes
    - Rename myUser ➡️ currentUser    
- Update resource property "id" ➡️ "urn" to match SoundCloud public API
    - These are now **String**
- Add support for [/resolve](https://developers.soundcloud.com/docs/api/explorer/open-api#/miscellaneous/get_resolve)

### 📋 API updates 
- Auth
    - login() → authenticate()
    - logout() → signOut()
    - authenticatedHeader (async property) → authorizationHeader
- Me / Social
    - getMyUser() → currentUser()
    - getUsersImFollowing() → usersIFollow()
    - getMyLikedTracks() → likedTracks()
    - getMyFollowingsRecentlyPosted() → followingFeed()
- Playlists
    - getMyPlaylistsWithoutTracks() → playlists()
    - getMyLikedPlaylistsWithoutTracks() → likedPlaylists()
    - getTracksForPlaylist(_:) → tracks(inPlaylist:)
- Users & Tracks
    - getTracksForUser(_:_:) → tracks(forUser:limit:)
    - getLikedTracksForUser(_:_:) → likedTracks(forUser:limit:)
    - getRelatedTracks(_:_:) → relatedTracks(to:limit:)
- Search
    - searchTracks(_: _:) → searchTracks(matching:limit:)
    - searchPlaylists(_: _:) → searchPlaylists(matching:limit:)
    - searchUsers(_: _:) → searchUsers(matching:limit:)
- Paging & Stream Info
    - pageOfItems(for:) → nextPage(from:)
    - getStreamInfoForTrack(with:) → streamInfo(for:)
- Actions
    - likeTrack(_:) → like(_ track: Track)
    - unlikeTrack(_:) → unlike(_ track: Track)
    - likePlaylist(_:) → like(_ playlist: Playlist)
    - unlikePlaylist(_:) → unlike(_ playlist: Playlist)
    - followUser(_:) → follow(_ user: User)
    - unfollowUser(_:) → unfollow(_ user: User)


## 1.2.0

### ✨ Features
- macOS 14 support
- Russian localized strings


## 1.1.0

### ✨ Features
- OAuth 2.1 (PKCE)
- API: add `SoundCloud.getRelatedTracks`
- Updated localized strings


## 1.0.4

### ✨ Features
- Dutch localized strings


## 1.0.3

### ✨ Features
- Portuguese (pt-br) localized strings


## 1.0.2

### 🐞 Bug fixes
- SoundCloud.Request api property is now private
- Remove unused SoundCloud.Error cases 


## 1.0.1

### 🐞 Bug fixes
- Remove @MainActor from `ASWebAuthenticationSession` async wrapper methods
- Add public init for `Page` 


## 1.0.0 

### ✨ Features
- SoundCloud instance no longer has stored/published properties
- Italian, Japanese localized strings
- Search API's all have limit parameters
- Page has empty static var
- Swift 5.9 switches as statements

### 🐞 Bug fixes
- Remove NSObject inheritance from SoundCloud instance


## 0.0.3 

### ✨ Features
- Spanish, Arabic localized strings
- APIs
    - loadUsersImFollowing
    - getTracksForUser
    - getLikedTracksForUser
    - follow + unfollow user
    - search tracks, playlists, users (artists)
    - generic page of items (for paginated responses)
    - like + unlike playlist

### 🐞 Bug fixes
- Translation errors
- User avatar url uses large image size
- Track.genre has to be optional


## 0.0.2 

### ✨ Features
- French, German localized strings

### 🐞 Bug fixes
- ASWebAuthenticationSession doesn't throw anymore if user cancels
- timeStringFromSeconds displays hour when exactly an hour (00:00 -> 1:00:00)

### Dependencies  
🔨 Swift tools version **5.9**⭐️
📦 KeychainSwift 20.0.0


## 0.0.1 (initial release)  

### Dependencies  
🔨 Swift tools version 5.8
📦 KeychainSwift 20.0.0
