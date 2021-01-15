//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/14/21.
//

import Foundation
import FirebaseFirestore

extension WriteBatch: WriteBatchInterface {
    func deleteDocumentInterface(_ document: DocumentReferenceInterface) {
        self.deleteDocument(document as! DocumentReference)
    }
    
    func updateDataInterface(
        _ fields: [AnyHashable : Any],
        forDocument: DocumentReferenceInterface
    ) {
        self.updateData(
            fields,
            forDocument:forDocument as! DocumentReference
        )
    }
    
    func setDataInterface(
        _ data: [String : Any],
        forDocument: DocumentReferenceInterface
    ) {
        self.setData(
            data,
            forDocument:forDocument as! DocumentReference
        )
    }
    
    
}
