//
//  User.swift
//
//
//  Created by Ryan Forsyth on 2023-10-03.
//

import Foundation

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
}

extension User: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public extension User {
    var subscription: String {
        (subscriptions.first?.product.name) ?? "Free"
    }
}
