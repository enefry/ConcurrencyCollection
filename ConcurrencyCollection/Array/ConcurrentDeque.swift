//
//  ConcurrentDeque.swift
//
//
//  Created by chenrenwei on 2023/5/31.
//

import Collections
import Foundation

public final class ConcurrentDeque<Element>: @unchecked Sendable {
    // MARK: - lifecycle

    public init(_ queue: DequeModule.Deque<Element> = DequeModule.Deque()) {
        data = SafeContainer(queue)
    }

    // MARK: data storage

    fileprivate var data: SafeContainer<DequeModule.Deque<Element>>
}

extension ConcurrentDeque: SafeOperation {
    // MARK: - SafeOperation

    public func safeWrite<T>(_ op: (inout DequeModule.Deque<Element>) throws -> T) rethrows -> T {
        try data.safeWrite(op)
    }

    public func safeGet<T>(_ op: (DequeModule.Deque<Element>) throws -> T) rethrows -> T {
        try data.safeGet(op)
    }

    public typealias RawCollectionType = DequeModule.Deque<Element>
}

extension ConcurrentDeque: Sequence {
    // Make a copy and return it's iterator
    public func makeIterator() -> DequeModule.Deque<Element>.Iterator {
        return safeGet { $0 }.makeIterator()
    }

    public typealias Element = Element

    public typealias Iterator = Deque<Element>.Iterator
}

extension ConcurrentDeque: Equatable where Element: Equatable {
    @inlinable
    public static func == (left: ConcurrentDeque, right: ConcurrentDeque) -> Bool {
        return left.safeGet { left2 in
            right.safeGet { right2 in
                left2 == right2
            }
        }
    }
}

public extension ConcurrentDeque {
    var count: Int {
        // Get the count of elements in the deque
        data.safeGet { $0.count }
    }

    @inlinable
    @inline(__always)
    var startIndex: Int {
        // The starting index is always 0
        0
    }

    @inlinable
    @inline(__always)
    var endIndex: Int {
        // The end index is equal to the count of elements
        return count
    }

    var indices: Range<Int> {
        // Get the range of valid indices
        data.safeGet { $0.indices }
    }

    @inlinable
    @inline(__always)
    func index(after i: Int) -> Int {
        // Return the next index
        i + 1
    }

    @inlinable
    @inline(__always)
    func formIndex(after i: inout Int) {
        // Increment the index by 1
        i += 1
    }

    @inlinable
    @inline(__always)
    internal func index(before i: Int) -> Int {
        // Return the previous index
        return i - 1
    }

    @inlinable
    @inline(__always)
    func formIndex(before i: inout Int) {
        // Decrement the index by 1
        i -= 1
    }

    @inlinable
    @inline(__always)
    func index(_ i: Int, offsetBy distance: Int) -> Int {
        // Return the index offset by the given distance
        return i + distance
    }

    @inlinable
    func index(
        _ i: Int,
        offsetBy distance: Int,
        limitedBy limit: Int
    ) -> Int? {
        // Return the index offset by the given distance, if within bounds of the limit
        let l = limit - i
        if distance > 0 ? (l >= 0 && l < distance) : (l <= 0 && distance < l) {
            return nil
        }
        return i + distance
    }

    @inlinable
    @inline(__always)
    func distance(from start: Int, to end: Int) -> Int {
        // Return the distance between two indices
        return end - start
    }

    @inlinable
    func firstIndex(where predicate: (Element) throws -> Bool, startingAt start: Int = 0) rethrows -> Int? {
        // Safely find the first index where the element satisfies the predicate, starting at a specified index
        return try safeGet { deque in
            for (index, element) in deque.enumerated() where index >= start {
                if try predicate(element) {
                    return index
                }
            }
            return nil
        }
    }

    @inlinable
    func lastIndex(where predicate: (Element) throws -> Bool, startingAt start: Int? = nil) rethrows -> Int? {
        // Safely find the last index where the element satisfies the predicate, optionally starting at a specified index
        return try safeGet { deque in
            let startIndex = start ?? deque.count - 1
            guard startIndex >= 0 else { return nil }
            for index in stride(from: startIndex, through: 0, by: -1) {
                if try predicate(deque[index]) {
                    return index
                }
            }
            return nil
        }
    }

    subscript(index: Int) -> Element? {
        get {
            // Safely get the element at the given index, if it exists
            data.safeGet { data in
                if index >= 0, index < data.count {
                    return data[index]
                }
                return nil
            }
        }
        set {
            if let value = newValue {
                // Safely set the element at the given index, if it is within bounds
                data.safeWrite { data in
                    if index >= 0, index < data.count {
                        data[index] = value
                    }
                }
            }
        }
    }

    func swapAt(_ i: Int, _ j: Int) {
        // Safely swap two elements at the given indices, if both are within bounds
        data.safeWrite {
            if i >= 0, i < $0.count,
               j >= 0, j < $0.count {
                $0.swapAt(i, j)
            }
        }
    }

    func insert(_ newElement: Element, at index: Int) {
        // Safely insert a new element at the given index, or append if the index is out of bounds
        data.safeWrite { data in
            if index >= 0 {
                if index < data.count {
                    data.insert(newElement, at: index)
                } else {
                    data.append(newElement)
                }
            }
        }
    }

    func insert<C: Collection>(
        contentsOf newElements: __owned C, at index: Int
    ) where C.Element == Element {
        // Safely insert a collection of new elements at the given index, or append if the index is out of bounds
        data.safeWrite { data in
            if index >= 0 {
                if index < data.count {
                    data.insert(contentsOf: newElements, at: index)
                } else {
                    data.append(contentsOf: newElements)
                }
            }
        }
    }

    func remove(at index: Int) -> Element? {
        // Safely remove an element at the given index, if it exists
        return data.safeWrite {
            if index >= 0,
               index < $0.count {
                return $0.remove(at: index)
            }
            return nil
        }
    }

    func removeSubrange(_ bounds: Range<Int>) {
        // Safely remove elements within the given range, if the range is within bounds
        data.safeWrite {
            if bounds.lowerBound >= 0,
               bounds.upperBound < $0.count {
                $0.removeSubrange(bounds)
            }
        }
    }

    func _customRemoveLast() -> Element? {
        // Safely remove and return the last element, if it exists
        return data.safeWrite {
            if $0.isEmpty {
                return nil
            } else {
                return $0.removeLast()
            }
        }
    }

    func _customRemoveLast(_ n: Int) -> Bool {
        // Safely remove the last n elements, if there are enough elements in the deque
        return data.safeWrite {
            if $0.count >= n {
                $0.removeLast(n)
                return true
            }
            return false
        }
    }

    func removeFirst() -> Element? {
        // Safely remove and return the first element, if it exists
        return data.safeWrite {
            if $0.isEmpty {
                return nil
            } else {
                return $0.removeFirst()
            }
        }
    }

    func removeFirst(_ n: Int) {
        // Safely remove the first n elements, up to the available count
        data.safeWrite { $0.removeFirst(Swift.min(n, $0.count)) }
    }

    func removeAll(keepingCapacity keepCapacity: Bool = false) {
        // Safely remove all elements from the deque, optionally keeping the capacity
        data.safeWrite { $0.removeAll(keepingCapacity: keepCapacity) }
    }

    func safeForEach(_ body: (Element) throws -> Void) rethrows {
        // Safely traverse the deque without allowing modifications during the iteration
        try safeGet { deque in
            for element in deque {
                try body(element)
            }
        }
    }
}

public extension ConcurrentDeque {
    func popFirst() -> Element? {
        // Safely remove and return the first element, if it exists
        return data.safeWrite { $0.popFirst() }
    }

    func prepend(_ newElement: Element) {
        // Safely prepend a new element to the deque
        data.safeWrite { $0.prepend(newElement) }
    }

    func prepend<C: Collection>(contentsOf newElements: C) where C.Element == Element {
        // Safely prepend a collection of new elements to the deque
        data.safeWrite { $0.prepend(contentsOf: newElements) }
    }

    func prepend<S: Sequence>(contentsOf newElements: S) where S.Element == Element {
        // Safely prepend a sequence of new elements to the deque
        data.safeWrite { $0.prepend(contentsOf: newElements) }
    }

    func append(_ newElement: Element) {
        // Safely append a new element to the deque
        data.safeWrite { $0.append(newElement) }
    }

    func append<S: Sequence>(contentsOf newElements: S) where S.Element == Element {
        // Safely append a sequence of new elements to the deque
        data.safeWrite { $0.append(contentsOf: newElements) }
    }

    func append<C: Collection>(contentsOf newElements: C) where C.Element == Element {
        // Safely append a collection of new elements to the deque
        data.safeWrite { $0.append(contentsOf: newElements) }
    }
}

extension ConcurrentDeque: Hashable where Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        // Safely hash the contents of the deque
        data.safeGet { $0.hash(into: &hasher) }
    }
}
