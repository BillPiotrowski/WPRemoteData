//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/14/21.
//

import Foundation
import FirebaseFirestore

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

// MARK: -
// MARK: DocumentSnapshotInterface
extension DocumentSnapshot: DocumentSnapshotInterface {
}
