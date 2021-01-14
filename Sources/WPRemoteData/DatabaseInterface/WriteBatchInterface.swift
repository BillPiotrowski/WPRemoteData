//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/14/21.
//

import Foundation
import FirebaseFirestore

protocol WriteBatchInterface {
    ///
    ///
    /// - warning: Introduces a risk because function has to typecheck `forDocumant` as `DocumentReference` and it does not throw. Should not be an issue as long as testing is not half on or half off.
    ///
    /// Will crash app if type is not correct.
    func setDataInterface(
        _ data: [String: Any],
        forDocument: DocumentReferenceInterface
    )
    
    ///
    ///
    /// - warning: Introduces a risk because function has to typecheck `forDocumant` as `DocumentReference` and it does not throw. Should not be an issue as long as testing is not half on or half off.
    ///
    /// Will crash app if type is not correct.
    func updateDataInterface(
        _ fields: [AnyHashable: Any],
        forDocument: DocumentReferenceInterface
    )
    
    ///
    ///
    /// - warning: Introduces a risk because function has to typecheck `document` as `DocumentReference` and it does not throw. Should not be an issue as long as testing is not half on or half off.
    ///
    /// Will crash app if type is not correct.
    func deleteDocumentInterface(
        _ document: DocumentReferenceInterface
    )
    
    func commit(completion: ((Error?) -> Void)?)
}


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
