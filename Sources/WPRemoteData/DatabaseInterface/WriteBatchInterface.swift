//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/14/21.
//

import Foundation

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

