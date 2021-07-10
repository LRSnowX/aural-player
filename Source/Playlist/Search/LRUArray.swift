//
//  LRUArray.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//  

import Foundation

/*
    A fixed-size array-based data structure that maintains the most recent n items, where n is the size of the array. This is useful, for instance, when keeping track of a fixed-size set of items in chronological order.
 */
class LRUArray<T: Equatable> {
    
    var array: [T] = [T]()
    
    // Adds a single new element to the array. If the array is already filled to capacity, the least recently added item will be removed to make room for the new element.
    func add(_ newElement: T) {
        
        // If the item already exists in array, remove it from the previous location (so it may be added at the top).
        _ = array.removeItem(newElement)
        
        // Add the new element at the end
        array.append(newElement)
    }
    
    // Removes a single element from the array, if it exists.
    func remove(_ element: T) {
        _ = array.removeItem(element)
    }
    
    // Retrieves the item at a given index. Returns nil if the given index is invalid.
    func itemAt(_ index: Int) -> T? {
        array.itemAtIndex(index)
    }
 
    // Returns a copy of the underlying array, maintaining the order of its elements
    func toArray() -> [T] {
        
        let arrayCopy = array
        return arrayCopy
    }
 
    // Checks if the array contains a particular element.
    func contains(_ element: T) -> Bool {
        array.contains(element)
    }
    
    func clear() {
        array.removeAll()
    }
}
