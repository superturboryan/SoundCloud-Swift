//
//  Page.swift
//
//
//  Created by Ryan Forsyth on 2023-10-03.
//

public struct Page<ItemType: Decodable>: Decodable {
    public var items: [ItemType]
    public var nextPageURL: String?
    
    public init(items: [ItemType], nextPage: String? = nil) {
        self.items = items
        self.nextPageURL = nextPage
    }
}

extension Page {
    public var hasNextPage: Bool { nextPageURL != nil }

    public mutating func update(with next: Page<ItemType>) {
        items += next.items
        nextPageURL = next.nextPageURL
    }
    
    internal enum CodingKeys: String, CodingKey {
        case items = "collection"
        case nextPageURL = "nextHref"
    }
}

public extension Page where ItemType == Track {
    func playlist(id: Int, title: String, user: User) -> Playlist {
        Playlist(
            id: id,
            user: user,
            title: title,
            tracks: self.items,
            nextPageUrl: self.nextPageURL
        )
    }
}

public extension Page {
    static var emptyPage: Page<ItemType> { Page(items: [], nextPage: nil) }
}
