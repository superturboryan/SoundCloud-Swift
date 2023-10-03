//
//  UserDefaultsService.swift
//  
//
//  Created by Ryan Forsyth on 2023-09-15.
//

import Foundation

internal struct UserDefaultsService<T: Codable>: ValuePersisting {
    internal typealias ValueType = T
    private let service = UserDefaults.standard
    
    internal var codingKey: String
    
    init(_ codingKey: String) {
        self.codingKey = codingKey
    }

    internal func get() -> T? {
        guard
            let valueData = service.object(forKey: codingKey) as? Data,
            let value = try? JSONDecoder().decode(T.self, from: valueData)
        else {
            return nil
        }
        return value
    }
    
    internal func save(_ value: T) {
        let valueData = try! JSONEncoder().encode(value)
        service.set(valueData, forKey: codingKey)
    }
    
    internal func delete() {
        service.set(nil, forKey: codingKey)
        service.removeObject(forKey: codingKey) // Double check with UD?
    }
}
