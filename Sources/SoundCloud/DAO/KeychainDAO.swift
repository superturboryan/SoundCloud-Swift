//
//  KeychainDAO.swift
//  
//
//  Created by Ryan Forsyth on 2023-08-30.
//

import Foundation
import KeychainSwift

public final class KeychainDAO<T: Codable>: DAO {
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let persistence = KeychainSwift()
    
    public var codingKey: String
    public init(_ codingKey: String) {
        self.codingKey = codingKey
    }

    public func get() throws -> T {
        guard let data = persistence.getData(codingKey) else {
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
        persistence.delete(codingKey)
    }
}
