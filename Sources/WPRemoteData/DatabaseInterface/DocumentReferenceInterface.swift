//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/14/21.
//

import Foundation

// MARK: DOCUMENT / REF
public protocol DocumentReferenceInterface {
    /// The ID of the document referred to.
    var documentID: String { get }
    
    /// A string representing the path of the referenced document (relative to the root of the database).
    var path: String { get }
    func getDocumentInterface(
        completion: @escaping (DocumentSnapshotInterface?, Error?)->Void
    )
    func addSnapshotListenerInterface(
        _ listener: @escaping (DocumentSnapshotInterface?, Error?)-> Void
    ) -> ListenerRegistrationInterface
    
    func setData(_ documentData: [String: Any], completion: ((Error?) -> Void)?)
}

// MARK: -
// MARK: DOCUMENT SNAPSHOT

/// An interface that models the Firestore database.
///
/// - note: This is not intended to be used publicly. Instead, should be mapped to `ScorepioDocumentResponse` which has specified generics.
public protocol DocumentSnapshotInterface {
    var documentID: String { get }
    func data() -> [String: Any]?
}



