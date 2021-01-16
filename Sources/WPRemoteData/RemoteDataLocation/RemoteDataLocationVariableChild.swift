//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/14/21.
//

import Foundation
import Promises
import ReactiveSwift

/// Describes a RemoteDataReference type that has variable IDs inside this collection. There may only be one of these per RemoteDataLocation (collection)
///
/// - warning: Ideally, there would not be any static children either when a variable child is defined. Could still work in theory, but would have a minor risk of overlap and is not clean architecturally.
public protocol RemoteDataLocationVariableChild: RemoteDataLocation {
    /// The child `RemoteDataReferenceGeneric` that is found in this location.
    associatedtype A: GettableRemoteDataDocument
}

extension RemoteDataLocation where
    Self: RemoteDataLocationVariableChild,
    Self == Self.A.Location,
    Self.A == Self.A.Data.RemoteDoc
{
    /// Gets all documents from the remote server at this `RemoteDataLocation` that satisfy the filter requirements.
    /// - Parameter filters: WhereFilters that are used to specify the server request.
    /// - Returns: Returns a `ScorepioQueryResponse` that includes an array of `ScorepioDocumentResponses` that are specific to the `RemoteDataReference` that is a variable ID child of `Self`.
    ///
    /// Response also contain specific `ReadableData` that are associated with `RemoteDataReference`.
    public func getAll(filters: [WhereFilter]? = nil) -> Promise<ScorepioQueryResponse<A,A.Data>>{
        let query = self.collectionReferenceInterface.getQuery(
            from: filters
        )
        return query.getAll().then {
            snapshot -> ScorepioQueryResponse<A,A.Data> in
            let documents = try snapshot.documentsInterface.map {
                return try self.createDocumentResponse(
                    snapshot: $0
                )
            }
            return ScorepioQueryResponse(documents: documents)
        }
    }
    
    public func addListener(
        filters: [WhereFilter]? = nil
    ) -> (
        ListenerRegistrationInterface,
        Signal<(ScorepioQueryResponse<A,A.Data>?, Error?), Never>
    ){
        let query = self.collectionReferenceInterface.getQuery(
            from: filters
        )
        let (disposable, signal) = query.addListener()
        let mappedSignal = signal.map{ snapshot, queryError -> (ScorepioQueryResponse<A,A.Data>?, Error?) in
            do {
                guard let snapshot = snapshot
                else { throw DatabaseInterfaceError.missingDocuments }
                let documents = try snapshot.documentsInterface.map {
                    return try self.createDocumentResponse(
                        snapshot: $0
                    )
                }
                return (
                    ScorepioQueryResponse(documents: documents),
                    queryError
                )
            } catch {
                return (nil, queryError ?? error)
            }
        }
        return (disposable, mappedSignal)
    }
    
    func createDocumentResponse(
        snapshot: DocumentSnapshotInterface
    ) throws -> ScorepioDocumentResponse<A, A.Data> {
        let reference = A(
            location: self,
            documentID: snapshot.documentID
        )
        let data = try reference.getData(snapshot: snapshot)
        return ScorepioDocumentResponse(
            reference: reference,
            data: data
        )
    }
}
