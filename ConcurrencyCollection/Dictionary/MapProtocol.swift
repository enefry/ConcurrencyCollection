//
//  MapProtocol.swift
//
//
//  Created by chenrenwei on 2023/5/31.
//

import Foundation

public protocol MapProtocol {
    associatedtype KEYType: Hashable
    associatedtype VALUEType
    func count() -> Int
    func keys() -> [KEYType]
    func values() -> [VALUEType]
    func contains(where: ((key: KEYType, value: VALUEType)) -> Bool) -> Bool
    func getValue(key: KEYType) -> VALUEType?
    func remove(key: KEYType) -> VALUEType?
    func set(key: KEYType, value: VALUEType?)
    func value(forKey key: KEYType) -> VALUEType?
    func mutateValue(forKey key: KEYType, mutation: (VALUEType) -> VALUEType)
    subscript(key: KEYType) -> VALUEType? { get set }
}
