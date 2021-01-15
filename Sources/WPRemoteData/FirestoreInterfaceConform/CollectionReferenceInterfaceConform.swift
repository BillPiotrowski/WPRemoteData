//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/14/21.
//

import Foundation
import FirebaseFirestore

extension CollectionReference: CollectionReferenceInterface {
    public func documentInterface(
        _ documentPath: String
    ) -> DocumentReferenceInterface {
        self.document(documentPath)
    }
    
    public func documentInterface() -> DocumentReferenceInterface {
        self.document()
    }
}
