//
//  UserDefaultsDAO.swift
//
//
//  Created by Ryan Forsyth on 2023-09-15.
//

import Foundation
/// Data access object used for persisting a `Codable` object to device's `UserDefaults`.
///
/// - Warning: **Unexpected behaviour across app launches:** `UserDefaults` may not be properly synchronized
/// after terminating app with Xcode. **Terminate app via device** for expected read-write behaviour.
public final class UserDefaultsDAO<T: Codable>: DAO {
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let persistence: UserDefaults
    
    public var codingKey: String
    public init(
        _ codingKey: String = "\(T.self)",
        _ userDefaults: UserDefaults = UserDefaults.standard
    ) {
        self.codingKey = codingKey
        self.persistence = userDefaults
    }

    public func get() throws -> T {
        guard let data = persistence.object(forKey: codingKey) as? Data else {
            throw DAOError.noData
        }
        guard let value = try? decoder.decode(T.self, from: data) else {
            throw DAOError.decoding
        }
        return value
    }
    
    public func save(_ value: T) throws {
        guard let data = try? encoder.encode(value) else {
            throw DAOError.encoding
        }
        persistence.set(data, forKey: codingKey)
    }
    
    public func delete() throws {
        persistence.set(nil, forKey: codingKey)
        persistence.removeObject(forKey: codingKey)
    }
}
