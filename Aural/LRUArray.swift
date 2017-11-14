import Cocoa

/*
    A fixed-size array-based data structure that maintains the most recent n items, where n is the size of the array. This is useful, for instance, when keeping track of a fixed-size set of items in chronological order.
 */
struct LRUArray<T: EquatableHistoryItem> {
    
    private var array: [T] = [T]()
    private let size: Int
    
    init(_ size: Int) {
        self.size = size
    }
    
    // Adds a single new element to the array. If the array is already filled to capacity, the least recently added item will be removed to make room for the new element.
    mutating func add(_ newElement: T) {
        
        if let index = array.index(where: { $0.equals(newElement) }) {
            
            // Item already exists in array, remove it from the previous location (so it may be added at the top)
            array.remove(at: index)
        }
        
        // Add the new element at the top
        array.append(newElement)
        
        // Max size has been reached, remove the oldest item
        if (array.count > size) {
            array.removeFirst()
        }
    }
    
    // Adds a set of new elements to the array. If the array is already filled to capacity, the least recently added item will be removed to make room for each new element.
    mutating func addAll(_ newElements: [T]) {
        newElements.forEach({add($0)})
    }
    
    // Removes a single element from the array, if it exists
    mutating func remove(_ element: T) {
       
        if let index = array.index(where: { $0.equals(element) }) {
            array.remove(at: index)
        }
    }
    
    // Retrieves the item at a given index. Returns nil if the given index is invalid.
    func itemAt(_ index: Int) -> T? {
        return (array.isEmpty || !(0..<array.count).contains(index)) ? nil : array[index]
    }
 
    // Returns a copy of the underlying array, maintaining the order of its elements
    func toArray() -> [T] {
        let arrayCopy = array
        return arrayCopy
    }
 
    // Checks if the array contains a particular element
    func contains(_ element: T) -> Bool {
        
        // Invoke EquatableHistoryItem.equals() to check for element equality
        return array.contains(where: { $0.equals(element) })
    }
}
