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

    public func safeGet<T>(_ op: (inout DequeModule.Deque<Element>) throws -> T) rethrows -> T {
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
        data.safeGet { $0.count }
    }

    @inlinable
    @inline(__always)
    var startIndex: Int {
        0
    }

    @inlinable
    @inline(__always)
    var endIndex: Int {
        return count
    }

    var indices: Range<Int> {
        data.safeGet { $0.indices }
    }

    @inlinable
    @inline(__always)
    func index(after i: Int) -> Int {
        i + 1
    }

    @inlinable
    @inline(__always)
    func formIndex(after i: inout Int) {
        i += 1
    }

    @inlinable
    @inline(__always)
    internal func index(before i: Int) -> Int {
        return i - 1
    }

    @inlinable
    @inline(__always)
    func formIndex(before i: inout Int) {
        // Note: Like `Array`, index manipulation methods on deques don't trap on
        // invalid indices. (Indices are still validated on element access.)
        i -= 1
    }

    @inlinable
    @inline(__always)
    func index(_ i: Int, offsetBy distance: Int) -> Int {
        // Note: Like `Array`, index manipulation methods on deques don't trap on
        // invalid indices. (Indices are still validated on element access.)
        return i + distance
    }

    @inlinable
    func index(
        _ i: Int,
        offsetBy distance: Int,
        limitedBy limit: Int
    ) -> Int? {
        // Note: Like `Array`, index manipulation methods on deques
        // don't trap on invalid indices.
        // (Indices are still validated on element access.)
        let l = limit - i
        if distance > 0 ? (l >= 0 && l < distance) : (l <= 0 && distance < l) {
            return nil
        }
        return i + distance
    }

    @inlinable
    @inline(__always)
    func distance(from start: Int, to end: Int) -> Int {
        // Note: Like `Array`, index manipulation method on deques
        // don't trap on invalid indices.
        // (Indices are still validated on element access.)
        return end - start
    }

    subscript(index: Int) -> Element? {
        get {
            data.safeGet { data in
                if index >= 0, index < data.count {
                    return data[index]
                }
                return nil
            }
        }
        set {
            if let value = newValue {
                data.safeWrite { data in
                    if index >= 0, index < data.count {
                        data[index] = value
                    }
                }
            }
        }
    }

    func swapAt(_ i: Int, _ j: Int) {
        data.safeWrite {
            if i >= 0, i < $0.count,
               j >= 0, j < $0.count
            {
                $0.swapAt(i, j)
            }
        }
    }

    func insert(_ newElement: Element, at index: Int) {
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
        data.safeWrite {
            if index >= 0,
               index < $0.count
            {
                return $0.remove(at: index)
            }
            return nil
        }
    }

    func removeSubrange(_ bounds: Range<Int>) {
        data.safeWrite {
            if bounds.lowerBound >= 0,
               bounds.upperBound < $0.count
            {
                $0.removeSubrange(bounds)
            }
        }
    }

    func _customRemoveLast() -> Element? {
        data.safeWrite {
            if $0.isEmpty {
                return nil
            } else {
                return $0._customRemoveLast()
            }
        }
    }

    func _customRemoveLast(_ n: Int) -> Bool {
        data.safeWrite { $0._customRemoveLast(Swift.min(n, $0.count)) }
    }

    func removeFirst() -> Element? {
        data.safeWrite {
            if $0.isEmpty {
                return nil
            } else {
                return $0.removeFirst()
            }
        }
    }

    func removeFirst(_ n: Int) {
        data.safeWrite { $0.removeFirst(Swift.min(n, $0.count)) }
    }

    func removeAll(keepingCapacity keepCapacity: Bool = false) {
        data.safeWrite { $0.removeAll(keepingCapacity: keepCapacity) }
    }
}

public extension ConcurrentDeque {
    func popFirst() -> Element? {
        return data.safeGet { $0.popFirst() }
    }

    func prepend(_ newElement: Element) {
        data.safeWrite { $0.prepend(newElement) }
    }

    func prepend<C: Collection>(contentsOf newElements: C) where C.Element == Element {
        data.safeWrite { $0.prepend(contentsOf: newElements) }
    }

    func prepend<S: Sequence>(contentsOf newElements: S) where S.Element == Element {
        data.safeWrite { $0.prepend(contentsOf: newElements) }
    }

    func append(_ newElement: Element) {
        data.safeWrite { $0.append(newElement) }
    }

    func append<S: Sequence>(contentsOf newElements: S) where S.Element == Element {
        data.safeWrite { $0.append(contentsOf: newElements) }
    }

    func append<C: Collection>(contentsOf newElements: C) where C.Element == Element {
        data.safeWrite { $0.append(contentsOf: newElements) }
    }
}

extension ConcurrentDeque: Hashable where Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        data.safeGet { $0.hash(into: &hasher) }
    }
}
