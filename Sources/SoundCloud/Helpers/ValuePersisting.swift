//
//  ValuePersisting.swift
//  
//
//  Created by Ryan Forsyth on 2023-08-30.
//

internal protocol ValuePersisting {
    associatedtype ValueType: Codable
    
    var codingKey: String { get }
    
    #warning("Errors not thrown")
    func get() -> ValueType?
    func save(_ value: ValueType) -> Void
    func delete()
}
