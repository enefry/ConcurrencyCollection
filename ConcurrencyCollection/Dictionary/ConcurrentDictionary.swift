//
//  ConcurrentDictionary.swift
//
//
//  Created by renwei.chen on 2021/12/28.
//

import Foundation

/// - Important: Note that this is a `class`, i.e. reference (not value) type
public final class ConcurrentDictionary<KEY: Hashable, VALUE>: SafeOperation, MapProtocol {
    // MARK: - SafeOperation

    public typealias RawCollectionType = Dictionary<KEY, VALUE>
    public typealias KEYType = KEY
    public typealias VALUEType = VALUE

    public func safeWrite<T>(_ op: (inout Dictionary<KEY, VALUE>) throws -> T) rethrows -> T {
        try data.safeWrite(op)
    }

    public func safeGet<T>(_ op: (inout Dictionary<KEY, VALUE>) throws -> T) rethrows -> T {
        try data.safeGet(op)
    }

    // MARK: - lifecycle

    public init(_ dict: Dictionary<KEY, VALUE> = [:]) {
        data = SafeContainer(dict)
    }

    // MARK: - MapProtocol

    /// get value for key
    /// @param key
    public func getValue(key: KEY) -> VALUE? {
        return self[key]
    }

    /// set value for key
    /// @param key
    /// @param value
    public func set(key: KEY, value: VALUE?) {
        self[key] = value
    }

    /// data count
    public func count() -> Int {
        data.safeGet { $0.count }
    }

    /// copy all keys
    public func keys() -> [KEY] {
        data.safeGet { Array($0.keys) }
    }

    /// copy all values
    public func values() -> [VALUE] {
        data.safeGet { Array($0.values) }
    }

    ///  check condition exists
    public func contains(where whereCondition: ((key: KEY, value: VALUE)) -> Bool) -> Bool {
        return data.safeGet { $0.contains(where: whereCondition) }
    }

    /// Sets the value for key
    ///
    /// - Parameters:
    ///   - value: The value to set for key
    ///   - key: The key to set value for
    public func set(value: VALUE, forKey key: KEY) {
        data.safeWrite { data in
            data[key] = value
        }
    }

    /// remove value by key
    @discardableResult
    public func remove(key: KEY) -> VALUE? {
        var result: VALUE?
        data.safeWrite { datas in
            result = datas.removeValue(forKey: key)
        }
        return result
    }

    public func remove(whereAll: (_ key: KEY, _ value: VALUE) -> Bool) {
        data.safeWrite { datas in
            var removeKeys: [KEY] = []
            datas.forEach { (key: KEY, value: VALUE) in
                if whereAll(key, value) {
                    removeKeys.append(key)
                }
            }
            removeKeys.forEach {
                datas.removeValue(forKey: $0)
            }
        }
    }

    /// check value is exists
    public func contains(_ key: KEY) -> Bool {
        return data.safeGet { $0.index(forKey: key) != nil }
    }

    /// get value by key
    public func value(forKey key: KEY) -> VALUE? {
        data.safeGet { $0[key] }
    }

    /// modify value by key and mutation
    public func mutateValue(forKey key: KEY, mutation: (VALUE) -> VALUE) {
        data.safeWrite { container in
            if let value = container[key] {
                container[key] = mutation(value)
            }
        }
    }

    /// remove all key and values
    public func removeAll() {
        data.safeWrite { $0.removeAll(keepingCapacity: true) }
    }

    // MARK: Subscript

    public subscript(key: KEY) -> VALUE? {
        get {
            return value(forKey: key)
        }
        set {
            data.safeWrite { datas in
                guard let newValue = newValue else {
                    datas.removeValue(forKey: key)
                    return
                }
                datas[key] = newValue
            }
        }
    }

    // MARK: - data

    private var data: SafeContainer<Dictionary<KEY, VALUE>>
}
