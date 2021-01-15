//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/14/21.
//

import Foundation
import Promises

public protocol RemoteDataLocationStaticChild1: RemoteDataLocation {
    associatedtype Static1: RemoteDataStaticReference
    var staticChild1: Static1 { get }
}

extension RemoteDataLocation where
    Self: RemoteDataLocationStaticChild1,
    Self == Static1.Location,
    Static1 == Static1.Data.Reference
{
    public func getChild1(
    ) -> Promise<ScorepioDocumentResponse<Static1,Static1.Data>> {
        return staticChild1.get()
    }
}
