//
//  ValuePersisting.swift
//  
//
//  Created by Ryan Forsyth on 2023-08-30.
//

internal protocol ValuePersisting {
    associatedtype ValueType: Codable
    func get() -> ValueType?
    func save(_ value: ValueType) -> Void
    func delete()
}

extension ValuePersisting {
    var codingKey: String { "\(ValueType.self)" }
}
