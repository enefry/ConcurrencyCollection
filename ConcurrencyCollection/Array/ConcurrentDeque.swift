//
//  ConcurrentDeque.swift
//
//
//  Created by chenrenwei on 2023/5/31.
//

import Collections
import Foundation

public final class ConcurrentDeque<Element> {
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
        return safeGet({ $0 }).makeIterator()
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

extension ConcurrentDeque {
    public var count: Int {
        data.safeGet { $0.count }
    }

    @inlinable
    @inline(__always)
    public var startIndex: Int {
        0
    }

    @inlinable
    @inline(__always)
    public var endIndex: Int {
        return count
    }

    public var indices: Range<Int> {
        data.safeGet { $0.indices }
    }

    @inlinable
    @inline(__always)
    public func index(after i: Int) -> Int {
        i + 1
    }

    @inlinable
    @inline(__always)
    public func formIndex(after i: inout Int) {
        i += 1
    }

    @inlinable
    @inline(__always)
    func index(before i: Int) -> Int {
        return i - 1
    }

    @inlinable
    @inline(__always)
    public func formIndex(before i: inout Int) {
        // Note: Like `Array`, index manipulation methods on deques don't trap on
        // invalid indices. (Indices are still validated on element access.)
        i -= 1
    }

    @inlinable
    @inline(__always)
    public func index(_ i: Int, offsetBy distance: Int) -> Int {
        // Note: Like `Array`, index manipulation methods on deques don't trap on
        // invalid indices. (Indices are still validated on element access.)
        return i + distance
    }

    @inlinable
    public func index(
        _ i: Int,
        offsetBy distance: Int,
        limitedBy limit: Int
    ) -> Int? {
        // Note: Like `Array`, index manipulation methods on deques
        // don't trap on invalid indices.
        // (Indices are still validated on element access.)
        let l = limit - i
        if distance > 0 ? l >= 0 && l < distance : l <= 0 && distance < l {
            return nil
        }
        return i + distance
    }

    @inlinable
    @inline(__always)
    public func distance(from start: Int, to end: Int) -> Int {
        // Note: Like `Array`, index manipulation method on deques
        // don't trap on invalid indices.
        // (Indices are still validated on element access.)
        return end - start
    }

    public subscript(index: Int) -> Element? {
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

    public func swapAt(_ i: Int, _ j: Int) {
        data.safeWrite {
            if 0 <= i, i < $0.count,
               0 <= j, j < $0.count {
                $0.swapAt(i, j)
            }
        }
    }

    public func insert(_ newElement: Element, at index: Int) {
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

    public func insert<C: Collection>(
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

    public func remove(at index: Int) -> Element? {
        data.safeWrite {
            if index >= 0,
               index < $0.count {
                return $0.remove(at: index)
            }
            return nil
        }
    }

    public func removeSubrange(_ bounds: Range<Int>) {
        data.safeWrite {
            if bounds.lowerBound >= 0,
               bounds.upperBound < $0.count {
                $0.removeSubrange(bounds)
            }
        }
    }

    public func _customRemoveLast() -> Element? {
        data.safeWrite {
            if $0.isEmpty {
                return nil
            } else {
                return $0._customRemoveLast()
            }
        }
    }

    public func _customRemoveLast(_ n: Int) -> Bool {
        data.safeWrite { $0._customRemoveLast(Swift.min(n, $0.count)) }
    }

    public func removeFirst() -> Element? {
        data.safeWrite {
            if $0.isEmpty {
                return nil
            } else {
                return $0.removeFirst()
            }
        }
    }

    public func removeFirst(_ n: Int) {
        data.safeWrite { $0.removeFirst(Swift.min(n, $0.count)) }
    }

    public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        data.safeWrite({ $0.removeAll(keepingCapacity: keepCapacity) })
    }
}

extension ConcurrentDeque {
    public func popFirst() -> Element? {
        return data.safeGet { $0.popFirst() }
    }

    public func prepend(_ newElement: Element) {
        data.safeWrite({ $0.prepend(newElement) })
    }

    public func prepend<C: Collection>(contentsOf newElements: C) where C.Element == Element {
        data.safeWrite { $0.prepend(contentsOf: newElements) }
    }

    public func prepend<S: Sequence>(contentsOf newElements: S) where S.Element == Element {
        data.safeWrite { $0.prepend(contentsOf: newElements) }
    }

    public func append(_ newElement: Element) {
        data.safeWrite { $0.append(newElement) }
    }

    public func append<S: Sequence>(contentsOf newElements: S) where S.Element == Element {
        data.safeWrite { $0.append(contentsOf: newElements) }
    }

    public func append<C: Collection>(contentsOf newElements: C) where C.Element == Element {
        data.safeWrite { $0.append(contentsOf: newElements) }
    }
}

extension ConcurrentDeque: Hashable where Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        data.safeGet { $0.hash(into: &hasher) }
    }
}
