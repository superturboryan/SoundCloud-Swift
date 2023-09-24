# SoundCloud
<img src="https://img.shields.io/badge/platforms-iOS%2013%20%7C%20watchOS%209-333333.svg" alt="SoundCloud supports iOS, macOS, and watchOS"/> <a href="https://github.com/apple/swift-package-manager" target="_blank"><img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg" alt="SoundCloud supports Swift Package Manager (SPM)"></a>

`SoundCloud` is a Swift Package 📦 that implements the **[SoundCloud Public API Specification (v1.0.0) ](https://developers.soundcloud.com/docs/api/)**. 

It handles the logic for authenticating with a SoundCloud account using the OAuth 2.0 standard, and provides an API for making authorized requests for streaming content and acessing track, artist, playlist data from SoundCloud.

## Installation
Add the following line to your project's dependencies in the Package.swift file:

```swift
.package(url: "https://github.com/superturboryan/SoundCloud-api"),
```

and include "SoundCloud" as a dependency for your executable target:

```swift
.target(name: "Your App", dependencies: ["SoundCloud", ...]),
```

## Setup
[Define a custom URL scheme for your app](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app), you will need to provide a redirect URI using the scheme so that the OAuth web page knows how to open your app when it receives the tokens callback.     
  
The redirect URI used when creating the SC instance must also be paired with the client ID and client secret for your [SoundCloud registered app](https://soundcloud.com/you/apps).

## Usage
To login using your SoundCloud account:

```swift
import SoundCloud

let config = SoundCloudConfig(apiURL: ...)
@StateObject var sc = SoundCloud(config)  
  
...
    
do {
    try await sc.login()
} catch {
    // Handle login error
}

```

To get the liked tracks for the current user:

```swift
let likedTracks = try await sc.getMyLikedTracks()
```


## Requirements
SoundCloud requires apps to be registered in order to access their public API. See [terms of use](https://developers.soundcloud.com/docs/api/terms-of-use)
