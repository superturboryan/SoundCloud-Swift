//
//  KeychainDAO.swift
//  
//
//  Created by Ryan Forsyth on 2023-08-30.
//

import Foundation
import KeychainSwift

public final class KeychainDAO<T: Codable>: DAO {
    public typealias DataType = T
    
    private let service = KeychainSwift()
    public var codingKey: String
    init(_ codingKey: String) {
        self.codingKey = codingKey
    }

    public func get() throws -> T {
        guard
            let valueData = service.getData(codingKey),
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
        service.delete(codingKey)
    }
}
