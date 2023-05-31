//
//  SSHTTPConcurrencyHelpers.swift
//
//
//  Created by renwei.chen on 2021/12/28.
//

import Foundation

public protocol RWLock {
    func writeLock()
    func readLock()
    func unlock()
}

public class PThreadRWLock: RWLock {
    private var lock: pthread_rwlock_t

    // MARK: Lifecycle

    deinit {
        pthread_rwlock_destroy(&lock)
    }

    public init() {
        lock = pthread_rwlock_t()
        var ret = pthread_rwlock_init(&lock, nil)
        if EAGAIN == ret || EBUSY == ret {
            pthread_rwlock_init(&lock, nil)
        }
        assert(ret == 0)
    }

    // MARK: Public

    public func writeLock() {
        pthread_rwlock_wrlock(&lock)
    }

    public func readLock() {
        pthread_rwlock_rdlock(&lock)
    }

    public func unlock() {
        pthread_rwlock_unlock(&lock)
    }
}

public protocol SafeOperation {
    associatedtype RawCollectionType
    mutating func safeWrite<T>(_ op: (inout RawCollectionType) -> T) -> T
    mutating func safeGet<T>(_ op: (inout RawCollectionType) -> T) -> T
}

public struct SafeContainer<RawCollectionType>: SafeOperation {
    public typealias RawCollectionType = RawCollectionType
    private let lock: RWLock = PThreadRWLock()
    private var container: RawCollectionType
    public init(_ container: RawCollectionType) {
        self.container = container
    }

    public mutating func safeWrite<T>(_ op: (inout RawCollectionType) -> T) -> T {
        lock.writeLock()
        defer {
            lock.unlock()
        }
        return op(&container)
    }

    public mutating func safeGet<T>(_ op: (inout RawCollectionType) -> T) -> T {
        lock.readLock()
        defer {
            lock.unlock()
        }
        return op(&container)
    }
}
