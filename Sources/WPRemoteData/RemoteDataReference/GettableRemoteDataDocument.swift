//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/14/21.
//

import Foundation
import Promises
import ReactiveSwift
import SPCommon

/// A protocol describing a `RemoteDataReference` with a known `Location` and can be instantiated by a `documentID` and that `RemoteDataLocation`.
public protocol GettableRemoteDataDocument: RemoteDataDocument {
    associatedtype Location: RemoteDataLocation
    
    /// Generic type defining document's `RemoteDataGeneric`.
    associatedtype Data: RemoteData
    
    /// Generic type defining document's location.
    ///
    /// - note: Will be used to set `RemoteDataReference` requirement for generalized location.
    ///
    /// Not entirely necessary to store location as generic, since all the data necessary comes from the non-generic `remoteDataLocationProtocol` property of `RemoteDataDocumentProtocol`, but since exact location is required for init, might as well store the exact reference as well.
    var location: Location { get }
    
    /// Initialize document from location and document ID.
    init(location: Location, documentID: String)
}

// MARK: CONFORM: RemoteDataReference
extension GettableRemoteDataDocument {
    public var remoteDataLocationProtocol: RemoteDataLocation {
        return location
    }
}


extension RemoteDataDocument where
    Self: GettableRemoteDataDocument,
    Self.Data.RemoteDoc == Self
{
    
    // MARK: -
    // MARK: GET
    /// Gets data document from server.
    /// - Returns: Returns a `ScorepioDocumentResponse` that contains data and `GettableRemoteDataDocument` Self. Has potential to store more information and metadata that is returned from server.
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
        try Data(remoteDocument: self, dictionary: dictionary)
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

extension RemoteDataDocument where
    Self: GettableRemoteDataDocument,
    Self.Data.RemoteDoc == Self,
    // THIS NEEDS TO BE REMOVED!!
//    Self.Data: ListenableRemoteData,
    Self.Data: WriteableData
{
    // Could eventually make a protocol that has a default value and this could be automatic.
    public func listenableDataContainer(
        initialData: Data,
        forTesting: Bool? = nil
    ) -> ListenableDataContainer<Data, Self> {
        return ListenableDataContainer<Data, Self>(
            initialData: initialData,
            forTesting: forTesting
        )
    }
}






// MARK: - Required for LocationStaticChild
/// Protocol used to descirbe a static child of `RemoteDataLocation`.
///
/// - RemoteDataLocationStaticChild1
/// - etc. if created
public protocol RemoteDataStaticReference: GettableRemoteDataDocument {
    static var name: String { get }
}


// MARK: - Build this out!
/// Protocol describing a document that has a static location `RemoteDataLocationVariableChild` with variable children `Self`.
///
/// Gives access to static methods `getAll` and `addListener` methods of parent.
///
/// - note: Can build out version for static child, but that seems less useful.
public protocol RemoteDataDocumentStaticLocation: GettableRemoteDataDocument {
    static var remoteDataLocation: Location { get }
}


/// Where Location has variable children and that child is self and self matches data's document.
extension RemoteDataDocumentStaticLocation where
    Location: RemoteDataLocationVariableChild,
    Self == Self.Location.A,
    Self == Self.Data.RemoteDoc
{
    public static func getAll(
        filters: [WhereFilter]? = nil
    ) -> Promise<ScorepioQueryResponse<Self, Self.Data>> {
        Self.remoteDataLocation.getAll(filters: filters)
    }
    
    
    public static func addListener(
        filters: [WhereFilter]? = nil
    ) -> (
        ListenerRegistrationInterface,
        Signal<(ScorepioQueryResponse<Self,Data>?, Error?), Never>
    ){
        Self.remoteDataLocation.addListener(filters: filters)
    }
    
    public var location: Self.Location {
        Self.remoteDataLocation
    }
}
