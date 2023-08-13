# SoundCloud
<img src="https://img.shields.io/badge/platforms-iOS%2013%20%7C%20macOS 10.15%20%7C%20watchOS%207-333333.svg" alt="SoundCloud supports iOS, macOS, and watchOS"/> <a href="https://github.com/apple/swift-package-manager" target="_blank"><img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg" alt="SoundCloud supports Swift Package Manager (SPM)"></a>

`SoundCloud` is a Swift Package 📦 that implements the **[SoundCloud Public API Specification (v1.0.0) ](https://developers.soundcloud.com/docs/api/)**. 

It handles the logic for authenticating with a SoundCloud account using the OAuth 2.0 standard, and provides an API for making authorized requests for streams and track, artist, playlist data from SoundCloud.

## Installation
To use SoundCloud in a project, add the following line to the dependencies in the Package.swift file:

```swift
.package(url: "https://github.com/superturboryan/SoundCloud-api"),
```

Include "SoundCloud" as a dependency for your executable target:

```swift
.target(name: "<target>", dependencies: ["SoundCloud"]),
```

Finally, `import SoundCloud` wherever you want to use it! 

## Setup
[Define a custom URL scheme for your app](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app), you will need to provide a URL scheme so that the OAuth login page knows how to open your app when it receives the OAuth tokens callback.

Add entries for `SC_CLIENT_ID`, `SC_CLIENT_SECRET`, and `SC_REDIRECT_URI` to the project's info.plist:

```
<key>SC_CLIENT_ID</key>
<string>$(SC_CLIENT_ID)</string>
<key>SC_CLIENT_SECRET</key>
<string>$(SC_CLIENT_SECRET)</string>
<key>SC_REDIRECT_URI</key>
<string>$(SC_REDIRECT_URI)</string>
```

## Usage
To login using your SoundCloud account:

```swift
@StateObject var sc = SC()
...
await sc.login()
```

To get the liked tracks for the current user:

```swift
try await sc.getMyLikedTracks()
```


## Requirements
SoundCloud requires apps to be registered in order to access their public API. See [terms of use](https://developers.soundcloud.com/docs/api/terms-of-use)
