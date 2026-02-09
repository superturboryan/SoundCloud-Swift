# SoundCloud (Swift)

![SoundCloud package banner light](https://github.com/user-attachments/assets/1f7b6a8a-3163-4dec-8e6b-8f1fba9d792c#gh-light-mode-only)
![SoundCloud package banner dark](https://github.com/user-attachments/assets/cd84d1db-596c-41a7-8823-047dd08b3f2b#gh-dark-mode-only)

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsuperturboryan%2FSoundCloud-Swift%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/superturboryan/SoundCloud-Swift)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsuperturboryan%2FSoundCloud-Swift%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/superturboryan/SoundCloud-Swift)

A lightweight Swift package for interacting with the public SoundCloud API. It handles OAuth 2.1 SSO and gives you convenient async/await APIs to access track, artist, and playlist data, as well as playable stream URLs.

## Features
- OAuth 2.1 authentication flow with **PKCE**
- Simple async/await interface
- Strongly-typed models for common SoundCloud entities
- Small surface area; focused on the essentials
- Works great in iOS/watchOS/macOS projects via Swift Package Manager

## Installation
`SoundCloud` is available via the [Swift Package Manager](https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/).   

Add this URL in **Xcode → Package Dependencies** (or to your `Package.swift`):

```
https://github.com/superturboryan/SoundCloud-Swift/
```

## Setup
1. **Register your app** on SoundCloud to obtain a client identifier and configure redirect URIs.
2. **Define a custom URL scheme** in your app so the OAuth callback can return control to your app.

- Apple docs: [Defining a custom URL scheme](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app)
- SoundCloud app management: [soundcloud.com/you/apps](https://soundcloud.com/you/apps)

> [!CAUTION]
> The redirect URI you use when registering your app with SoundCloud **must match one of the redirect URIs configured for your SoundCloud app**.

## Quick Start
Authenticate with a SoundCloud account:

```swift
import SoundCloud

let config = SoundCloud.Config(clientId: /* your client id */)
@StateObject var sc = SoundCloud(config)

// ... later, e.g. from a button tap
Task {
    do {
        try await sc.authenticate()
    } catch {
        // Handle login error
        print(error)
    }
}
```

## Usage Examples
Get the authenticated user's liked tracks:

```swift
let likedTracks = try await sc.likedTracks()
```

> Looking for other endpoints? Check the sources for additional convenience APIs and models.

## Requirements
Access to the SoundCloud Public API requires a registered app and compliance with their terms:
- SoundCloud Public API specification: <https://developers.soundcloud.com/docs/api/explorer/open-api>
- API Terms of Use: <https://developers.soundcloud.com/docs/api/terms-of-use>

## Migration Notes
If you're upgrading from `< 2.0.0`, note the switch from numeric IDs to string **URNs** introduced by SoundCloud. Expect types touching `id` fields to change to `String`. Review any code paths that parse or store numeric IDs and update persistence accordingly. See: <https://developers.soundcloud.com/blog/urn-num-to-string>.

## Example Apps
[<img alt="WatchCloud" src="https://github.com/user-attachments/assets/96ffcaa8-da08-4ab8-9b65-f0c5d2329bfb" width=60/>](https://apps.apple.com/us/app/watchcloud/id6466678799) 

This package powers the third‑party SoundCloud watchOS app **WatchCloud** — available on the [App Store](https://apps.apple.com/us/app/watchcloud/id6466678799) 📲

If you use this package in your app, let me know and I'll give you a shout‑out! 👋

## Contributing
Issues and PRs welcome! 🙌

---

Banner icon made with [**Strata**](https://apps.apple.com/us/app/strata-icon-generator/id6742242942) 🧡
