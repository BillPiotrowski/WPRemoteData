//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/13/21.
//

import Foundation

/// An interface with the Firebase `Query` object. Exposes underlying methods in a neutral, non Firebase specific way.
///
/// Unsure if it is a class that is inherited by `CollectionReference` or if `Query` is a protocol that `CollectionReference` conforms to.
public protocol QueryInterface {
    func whereFieldInterface(
        _ fields: [String],
        isEqualTo: Any
    ) -> QueryInterface
    
    func whereFieldInterface(
        _ fields: [String],
        isGreaterThan: Any
    ) -> QueryInterface
    
    func whereFieldInterface(
        _ fields: [String],
        isGreaterThanOrEqualTo: Any
    ) -> QueryInterface
    
    func whereFieldInterface(
        _ fields: [String],
        isLessThan: Any
    ) -> QueryInterface
    
    func whereFieldInterface(
        _ fields: [String],
        isLessThanOrEqualTo: Any
    ) -> QueryInterface
    
    /// The immediate interface with the protocol modelling the Firebase server.
    ///
    /// - warning: Should not be exposed publicly.
    func getDocumentsInterface(
        completion: @escaping (QuerySnapshotInterface?, Error?) -> Void
    )
    
    /// The immediate interface with the protocol modelling the Firebase server.
    ///
    /// - warning: Should not be exposed publicly.
    func addSnapshotListenerInterface(
        _ listener: @escaping (QuerySnapshotInterface?, Error?)-> Void
    ) -> ListenerRegistrationInterface
    
}



// MARK: -
// MARK: QuerySnapshotInterface
/// An interface that models the Firestore database.
///
/// - note: This is not intended to be used publicly. Instead, should be mapped to `ScorepioQueryResponse` which has specified generics.
///
/// Should be internal.
public protocol QuerySnapshotInterface {
    var documentsInterface: [DocumentSnapshotInterface] { get }
}


