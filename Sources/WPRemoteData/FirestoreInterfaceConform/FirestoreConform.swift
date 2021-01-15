//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/14/21.
//

import Foundation
import FirebaseFirestore

extension Firestore: DatabaseInterface {
    public func collectionInterface(_ collectionPath: String) -> CollectionReferenceInterface {
        return self.collection(collectionPath)
    }
}
