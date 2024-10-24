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
    private var lock: pthread_rwlock_t = pthread_rwlock_t()
    
    // MARK: Lifecycle
    
    public init() {
        // Initialize the pthread read-write lock and assert if initialization fails
        let ret = pthread_rwlock_init(&lock, nil)
        assert(ret == 0, "Failed to initialize pthread_rwlock")
    }
    
    deinit {
        // Destroy the pthread read-write lock on deinitialization
        pthread_rwlock_destroy(&lock)
    }
    
    // MARK: Public
    
    public func writeLock() {
        // Acquire write lock
        pthread_rwlock_wrlock(&lock)
    }
    
    public func readLock() {
        // Acquire read lock
        pthread_rwlock_rdlock(&lock)
    }
    
    public func unlock() {
        // Release lock
        pthread_rwlock_unlock(&lock)
    }
}

public protocol SafeOperation {
    associatedtype RawCollectionType
    // Method to safely write to the container
    mutating func safeWrite<T>(_ op: (inout RawCollectionType) throws -> T) rethrows -> T
    // Method to safely read from the container
    func safeGet<T>(_ op: (RawCollectionType) throws -> T) rethrows -> T
}

public struct SafeContainer<RawCollectionType>: SafeOperation, @unchecked Sendable {
    private let lock: RWLock = PThreadRWLock()
    private var container: RawCollectionType
    
    public init(_ container: RawCollectionType) {
        self.container = container
    }
    
    public mutating func safeWrite<T>(_ op: (inout RawCollectionType) throws -> T) rethrows -> T {
        // Acquire write lock before performing operation
        lock.writeLock()
        defer {
            // Ensure lock is released after the operation
            lock.unlock()
        }
        return try op(&container)
    }
    
    public func safeGet<T>(_ op: (RawCollectionType) throws -> T) rethrows -> T {
        // Acquire read lock before performing operation
        lock.readLock()
        defer {
            // Ensure lock is released after the operation
            lock.unlock()
        }
        return try op(container)
    }
}
