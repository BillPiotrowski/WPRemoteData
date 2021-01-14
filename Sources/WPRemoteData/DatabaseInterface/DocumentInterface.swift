//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/14/21.
//

import Foundation
import FirebaseFirestore

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
extension DocumentReference: DocumentReferenceInterface {
    public func addSnapshotListenerInterface(
        _ listener: @escaping (DocumentSnapshotInterface?, Error?) -> Void
    ) -> ListenerRegistrationInterface {
        self.addSnapshotListener(){ snapshot, error in
            listener(snapshot, error)
        }
    }
    
    public func getDocumentInterface(completion: @escaping (DocumentSnapshotInterface?, Error?) -> Void) {
        self.getDocument(){ snapshot, error in
            completion(snapshot, error)
        }
    }
    
    
    
}

struct DummyDatabaseDocument {
    let documentID: String
    init(){
        self.documentID = "randomStringID"
    }
}
//extension DummyDatabaseDocument: DocumentReferenceInterface {
//
//}




// MARK: DOCUMENT SNAPSHOT
public protocol DocumentSnapshotInterface {
    var documentID: String { get }
    func data() -> [String: Any]?
}
extension DocumentSnapshot: DocumentSnapshotInterface {
}
