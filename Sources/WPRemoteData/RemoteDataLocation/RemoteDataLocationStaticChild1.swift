//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/14/21.
//

import Foundation
import Promises

/// - note:Not sure how necessary this is because callers would likely just use the actual doc reference insead of navigating via parent folder.
///
/// Will need to build out duplicates of this in the future if it is useful.
public protocol RemoteDataLocationStaticChild1: RemoteDataLocation {
    associatedtype Static1: RemoteDataStaticReference
    var staticChild1: Static1 { get }
}

extension RemoteDataLocation where
    Self: RemoteDataLocationStaticChild1,
    Self == Static1.Location,
    Static1 == Static1.Data.RemoteDoc
{
    public func getChild1(
    ) -> Promise<ScorepioDocumentResponse<Static1,Static1.Data>> {
        return staticChild1.get()
    }
}





public protocol RemoteDataLocationStaticChild2: RemoteDataLocation {
    associatedtype Static2: RemoteDataStaticReference
    var staticChild2: Static2 { get }
}

extension RemoteDataLocation where
    Self: RemoteDataLocationStaticChild2,
    Self == Static2.Location,
    Static2 == Static2.Data.RemoteDoc
{
    public func getChild2(
    ) -> Promise<ScorepioDocumentResponse<Static2,Static2.Data>> {
        return staticChild2.get()
    }
}
