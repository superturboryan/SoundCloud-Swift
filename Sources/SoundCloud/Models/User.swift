//
//  User.swift
//
//
//  Created by Ryan Forsyth on 2023-10-03.
//

public struct User: Codable, Equatable {
    public let avatarUrl: String
    public let id: Int
    public let permalinkUrl: String
    public let uri: String
    public let username: String
    public let createdAt: String
    public let firstName: String?
    public let lastName: String?
    public let fullName: String
    public let city: String?
    public let country: String?
    public let description: String?
    public let trackCount: Int
    public let repostsCount: Int
    public let followersCount: Int
    public let followingsCount: Int
    public let commentsCount: Int
    public let online: Bool
    public let likesCount: Int
    public let playlistCount: Int
    public let subscriptions: [Subscription]
    
    public init(
        avatarUrl: String = "",
        id: Int,
        permalinkUrl: String = "",
        uri: String = "",
        username: String = "",
        createdAt: String = "",
        firstName: String? = nil,
        lastName: String? = nil,
        fullName: String = "",
        city: String? = nil,
        country: String? = nil,
        description: String? = nil,
        trackCount: Int = 0,
        repostsCount: Int = 0,
        followersCount: Int = 0,
        followingsCount: Int = 0,
        commentsCount: Int = 0,
        online: Bool = false,
        likesCount: Int = 0,
        playlistCount: Int = 0,
        subscriptions: [Subscription] = []
    ) {
        self.avatarUrl = avatarUrl
        self.id = id
        self.permalinkUrl = permalinkUrl
        self.uri = uri
        self.username = username
        self.createdAt = createdAt
        self.firstName = firstName
        self.lastName = lastName
        self.fullName = fullName
        self.city = city
        self.country = country
        self.description = description
        self.trackCount = trackCount
        self.repostsCount = repostsCount
        self.followersCount = followersCount
        self.followingsCount = followingsCount
        self.commentsCount = commentsCount
        self.online = online
        self.likesCount = likesCount
        self.playlistCount = playlistCount
        self.subscriptions = subscriptions
    }
}

public extension User {
    var subscription: String {
        (subscriptions.first?.product.name) ??  String(localized: "Free", comment: "Adjective")
    }
    
    var largerAvatarUrl: String {
        avatarUrl.replacingOccurrences(of: "large.jpg", with: "t500x500.jpg")
    }
}

extension User: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public extension User {
    struct Subscription: Codable, Equatable {
        public let product: Product

        public struct Product: Codable, Equatable {
            public let id: String
            public let name: String
        }
    }
}
