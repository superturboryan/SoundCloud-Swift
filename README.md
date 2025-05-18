
![SoundCloud package banner light](https://github.com/user-attachments/assets/1f7b6a8a-3163-4dec-8e6b-8f1fba9d792c#gh-light-mode-only)    
![SoundCloud package banner dark](https://github.com/user-attachments/assets/cd84d1db-596c-41a7-8823-047dd08b3f2b#gh-dark-mode-only)       
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsuperturboryan%2FSoundCloud-Swift%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/superturboryan/SoundCloud-Swift) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsuperturboryan%2FSoundCloud-Swift%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/superturboryan/SoundCloud-Swift)

**`SoundCloud`** is a Swift Package that implements the [SoundCloud Public API Specification (v1.0.0) ](https://developers.soundcloud.com/docs/api/explorer/open-api). 

It handles the logic for authenticating with a SoundCloud account using the OAuth 2.1 standard, **including PKCE**, and provides an API for streaming audio and accessing track, artist, and playlist data from SoundCloud.

## Installation
`SoundCloud` is available via the Swift Package Manager. Copy the repo link into the search bar:
```
https://github.com/superturboryan/SoundCloud-Swift/
```
![Screenshot 2025-05-18 at 10 25 05](https://github.com/user-attachments/assets/d074206a-2222-478a-a920-80296383326e)

## Setup
[Define a custom URL scheme for your app](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app), you will need to provide a redirect URI using the scheme so that the OAuth web page knows how to open your app when it receives the tokens callback:

![Screenshot 2025-05-18 at 10 22 49](https://github.com/user-attachments/assets/bf6a19a1-e7b2-40be-87d1-98a447a73071)  


The redirect URI used when creating the `SoundCloud` instance must also be paired with the client ID and client secret for your [SoundCloud registered app](https://soundcloud.com/you/apps).

## Usage
To login using a SoundCloud account:

```swift
import SoundCloud

let config = SoundCloudConfig(clientId: ...)
@StateObject var sc = SoundCloud(config)  
  
...  

    
do {
    try await sc.login()
} catch {
    // Handle login error
}

```

To get the liked tracks for the authenticated user:

```swift
let likedTracks = try await sc.getMyLikedTracks()
```

## Example apps
This package is used by the third-party SoundCloud watchOS app **WatchCloud**, check it out on the [App Store](https://apps.apple.com/us/app/watchcloud/id6466678799) 📲


## Requirements
SoundCloud requires apps to be registered in order to access their public API. 
See [terms of use](https://developers.soundcloud.com/docs/api/terms-of-use).  

<br/>  

Banner icon made with [**Strata**](https://apps.apple.com/us/app/strata-icon-generator/id6742242942) 🧡
