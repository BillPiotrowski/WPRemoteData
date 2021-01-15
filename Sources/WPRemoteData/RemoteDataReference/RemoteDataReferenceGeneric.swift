//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/14/21.
//

import Foundation
import Promises
import ReactiveSwift

/// A protocol describing a `RemoteDataReference` with a known `Location` and can be instantiated by a `documentID` and that `RemoteDataLocation`.
public protocol RemoteDataReferenceGeneric: RemoteDataReference {
    associatedtype Location: RemoteDataLocation
    
    /// Generic type defining document's `RemoteDataGeneric`.
    associatedtype Data: RemoteDataGeneric
    
    /// Generic type defining document's location.
    ///
    /// - note: Will be used to set `RemoteDataReference` requirement for generalized location.
    var location: Location { get }
    
    /// Initialize document from location and document ID.
    init(location: Location, documentID: String)
}

// MARK: CONFORM: RemoteDataReference
extension RemoteDataReferenceGeneric {
    public var remoteDataLocation: RemoteDataLocation {
        return location
    }
}



// Move init to new protocol named Getable / Findable / Searchable.





extension RemoteDataReference where
    Self: RemoteDataReferenceGeneric,
    Self.Data.Reference == Self
{
    
    // MARK: -
    // MARK: GET
    public func get(
    ) -> Promise<ScorepioDocumentResponse<Self, Data>> {
        return self.documentReference.get().then {
            snapshot -> ScorepioDocumentResponse<Self, Data> in
            let data = try self.getData(snapshot: snapshot)
            return ScorepioDocumentResponse(
                reference: self,
                data: data
            )
        }
    }
    
    // MARK: -
    // MARK: ADD LISTENER
    public func addListener() ->(ListenerRegistrationInterface, Signal<(ScorepioDocumentResponse<Self, Self.Data>?, Error?), Never>){
        let (disposable, signal) = self.documentReference.addListener()
        let mappedSignal = signal.map {
            response, queryError -> (ScorepioDocumentResponse<Self, Data>?, Error?) in
            do {
                guard let response = response
                else {
                    throw DatabaseInterfaceError.missingDocument(
                        path: self.documentReference.path
                    )
                }
                let data = try self.getData(snapshot: response)
                let doc = ScorepioDocumentResponse(
                    reference: self,
                    data: data
                )
                return (doc, queryError)
            } catch {
                return (nil, queryError ?? error)
            }
        }
        return (disposable, mappedSignal)
    }
    
    // MARK: -
    // MARK: HELPERS
    func getData(dictionary: [String: Any]) throws -> Data {
        try Data(remoteDataReference: self, dictionary: dictionary)
    }
    
    func getData(
        snapshot: DocumentSnapshotInterface
    ) throws -> Data {
        guard let dictionary = snapshot.data()
        else {
            throw DatabaseInterfaceError.missingData(
                dataType: String(describing: Data.self),
                path: self.path
            )
        }
        return try getData(dictionary: dictionary)
    }
}







// MARK: -
public protocol RemoteDataStaticReference: RemoteDataReferenceGeneric {
    static var name: String { get }
}
