//
//  ConcurrentDictionary.swift
//
//
//  Created by renwei.chen on 2021/12/28.
//

import Foundation
import OrderedCollections

public final class ConcurrentOrderedDictionary<KEY: Hashable, VALUE> {
    public init(_ dictionary: OrderedDictionary<KEY, VALUE> = OrderedDictionary()) {
        data = SafeContainer(dictionary)
    }

    fileprivate var data: SafeContainer<OrderedDictionary<KEY, VALUE>>
}

extension ConcurrentOrderedDictionary: SafeOperation {
    public typealias RawCollectionType = OrderedDictionary<KEY, VALUE>

    public func safeWrite<T>(_ op: (inout OrderedCollections.OrderedDictionary<KEY, VALUE>) throws -> T) rethrows -> T {
        try data.safeWrite(op)
    }

    public func safeGet<T>(_ op: (inout OrderedCollections.OrderedDictionary<KEY, VALUE>) throws -> T) rethrows -> T {
        try data.safeGet(op)
    }
}

extension ConcurrentOrderedDictionary: MapProtocol {
    public typealias KEYType = KEY
    public typealias VALUEType = VALUE

    public func contains(where whereCondition: ((key: KEY, value: VALUE)) -> Bool) -> Bool {
        data.safeGet { $0.contains(where: whereCondition) }
    }

    public func set(key: KEY, value: VALUE?) {
        data.safeWrite { $0[key] = value }
    }

    public func count() -> Int {
        data.safeGet { $0.count }
    }

    public func keys() -> [KEY] {
        data.safeGet { $0.keys.elements }
    }

    public func values() -> [VALUE] {
        data.safeGet { $0.values.elements }
    }

    public func value(forKey key: KEY) -> VALUE? {
        data.safeGet { $0[key] }
    }

    public func getValue(key: KEY) -> VALUE? {
        value(forKey: key)
    }

    public func mutateValue(forKey key: KEY, mutation: (VALUE) -> VALUE) {
        data.safeWrite { data in
            if let value = data[key] {
                data[key] = mutation(value)
            }
        }
    }

    public subscript(key: KEY) -> VALUE? {
        get {
            value(forKey: key)
        }
        set(newValue) {
            set(key: key, value: newValue)
        }
    }

    public func remove(key: KEY) -> VALUE? {
        data.safeWrite {
            if let ret = $0[key] {
                $0.removeValue(forKey: key)
                return ret
            }
            return nil
        }
    }

    public func moveBy(from: Int, to: Int) -> Bool {
        if from != to {
            return safeWrite { datas in
                if 0 <= from, from < datas.count,
                   0 <= to, to < datas.count {
                    let key = datas.keys[from]
                    let value = datas.values[from]
                    datas.remove(at: from)
                    datas.updateValue(value, forKey: key, insertingAt: to)
                    return true
                } else {
                    return false
                }
            }
        } else {
            return true
        }
    }

    public func moveBy(fromKey: KEY, to: Int) -> Bool {
        safeWrite { datas in
            if let value = datas[fromKey],
               0 <= to, to < datas.count {
                datas.removeValue(forKey: fromKey)
                datas.updateValue(value, forKey: fromKey, insertingAt: to)
                return true
            } else {
                return false
            }
        }
    }
}
