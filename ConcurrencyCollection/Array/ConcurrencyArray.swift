//
//  ConcurrencyArray.swift
//
//
//  Created by renwei.chen on 2021/12/28.
//

import Foundation

/// Thread-safe array wrapper
/// - Important: Note that this is a `class`, i.e. reference (not value) type
public final class ConcurrentArray<Element>: SafeOperation {
    // MARK: - SafeOperation
    
    public typealias RawCollectionType = Array<Element>
    public func safeWrite<T>(_ op: (inout Array<Element>) -> T) -> T {
        data.safeWrite(op)
    }
    
    public func safeGet<T>(_ op: (inout Array<Element>) -> T) -> T {
        data.safeGet(op)
    }
    
    // MARK: Lifecycle
    
    public init(_ array: Array<Element> = []) {
        data = SafeContainer(array)
    }
    
    // MARK: Public data operator
    
    ///
    /// copy all values
    public var values: [Element] {
        return data.safeGet { $0 }
    }
    
    /// get data count
    public var count: Int {
        data.safeGet { $0.count }
    }
    
    /// array is empty
    public var isEmpty: Bool {
        data.safeGet { $0.isEmpty }
    }
    
    /// append new element
    public func append(_ newElement: Element) {
        data.safeWrite { $0.append(newElement) }
    }
    
    /// add new elements from Sequence
    public func append(contentsOf sequence: any Sequence<Element>) {
        data.safeWrite { $0.append(contentsOf: sequence) }
    }
    
    /// remove element at index
    public func remove(at index: Int) -> Element? {
        return data.safeWrite { $0.remove(at: index) }
    }
    
    /// remove All elements
    public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        data.safeWrite { $0.removeAll(keepingCapacity: keepCapacity) }
    }
    
    /// remove first element
    public func removeFirst(_ k: Int) {
        data.safeWrite { data in
            if !data.isEmpty {
                data.removeFirst(k)
            }
        }
    }
    
    /// remove element with condition
    public func removeAll(where condition: (Element) -> Bool) {
        data.safeWrite { datas in
            datas.removeAll(where: condition)
        }
    }
    
    /// remove first item and return it if exists
    @discardableResult
    public func removeFirst() -> Element? {
        var result: Element?
        data.safeWrite { data in
            if !data.isEmpty {
                result = data.removeFirst()
            }
        }
        return result
    }
    
    /// remove last item and return it if exists
    @discardableResult
    public func removeLast() -> Element? {
        var result: Element?
        data.safeWrite { data in
            if !data.isEmpty {
                result = data.removeLast()
            }
        }
        return result
    }
    
    /// get element at index
    public func value(at index: Int) -> Element? {
        return data.safeGet {
            if index >= 0,
               $0.count > index {
                return $0[index]
            } else {
                return nil
            }
        }
    }
    
    /// modify element at index
    public func mutateValue(at index: Int, mutation: (Element) -> Element) {
        data.safeWrite { container in
            if index >= 0,
               container.count > index {
                let value = container[index]
                container[index] = mutation(value)
            }
        }
    }
    
    /// find element
    public func find(_ whereCondition: (Element) -> Bool) -> Element? {
        var result: Element?
        for item in data.safeGet({ $0 }) {
            if whereCondition(item) {
                result = item
                break
            }
        }
        return result
    }
    
    // MARK: Subscript
    
    public subscript(index: Int) -> Element? {
        get {
            return value(at: index)
        }
        set {
            if let value = newValue {
                data.safeWrite { datas in
                    datas[index] = value
                }
            }
        }
    }
    
    
    // MARK: private data
    
    fileprivate var data: SafeContainer<Array<Element>>
}
