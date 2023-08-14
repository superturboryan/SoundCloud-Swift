//
//  Collection.swift
//  SC Demo
//
//  Created by Ryan Forsyth on 2023-08-13.
//

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    public subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
