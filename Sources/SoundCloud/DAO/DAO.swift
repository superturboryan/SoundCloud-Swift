//
//  DAO.swift
//  
//
//  Created by Ryan Forsyth on 2023-08-30.
//

/// Describes a data access object used for persisting an item of generic `Codable` type `DataType`
 /// - Parameters:
///   - codingKey: key used to encode + decode persisted object
public protocol DAO<DataType>: AnyObject {
    associatedtype DataType: Codable
    
    var codingKey: String { get }
    
    func get() throws -> DataType
    func save(_ value: DataType) throws
    func delete() throws
}

public enum DAOError: Error {
    case noData
    case decoding
    case encoding
}
