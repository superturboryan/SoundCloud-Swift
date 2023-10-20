//
//  UserDefaultsDAO.swift
//
//
//  Created by Ryan Forsyth on 2023-09-15.
//

import Foundation

public final class UserDefaultsDAO<T: Codable>: DAO {
    public typealias DataType = T
    
    private let service = UserDefaults.standard
    public var codingKey: String
    public init(_ codingKey: String) {
        self.codingKey = codingKey
    }

    public func get() throws -> T {
        guard
            let valueData = service.object(forKey: codingKey) as? Data,
            let value = try? JSONDecoder().decode(T.self, from: valueData)
        else {
            throw DAOError.decoding
        }
        return value
    }
    
    public func save(_ value: T) throws {
        guard let data = try? JSONEncoder().encode(value) else {
            throw DAOError.encoding
        }
        service.set(data, forKey: codingKey)
    }
    
    public func delete() throws {
        service.set(nil, forKey: codingKey)
        service.removeObject(forKey: codingKey)
    }
}
