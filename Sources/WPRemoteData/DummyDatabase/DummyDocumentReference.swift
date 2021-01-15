//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/14/21.
//

import Foundation

class DummyDocumentReference {
    private let collectionReference: DummyCollectionReference
    private let relativePath: String
    internal private (set) var hasListener: Bool = false
    
    init(
        collectionReference: DummyCollectionReference,
        relativePath: String? = nil
    ){
        let relativePath = relativePath ?? "GeneratedID"
        self.collectionReference = collectionReference
        self.relativePath = relativePath
        
    }
}

// MARK: -
// MARK: CONFORM
extension DummyDocumentReference: DocumentReferenceInterface {
    var documentID: String {
        let array = path.split(separator: "/")
        return String(array.last!)
    }
    
    var path: String {
        return "\(collectionReference.path)/\(relativePath)"
    }
    
    func getDocumentInterface(completion: @escaping (DocumentSnapshotInterface?, Error?) -> Void) {
        completion(nil, NSError(domain: "no doc", code: 1))
    }
    
    func addSnapshotListenerInterface(
        _ listener: @escaping (DocumentSnapshotInterface?, Error?) -> Void
    ) -> ListenerRegistrationInterface {
        self.hasListener = true
        let disposable = DummyDisposable(){
            self.hasListener = false
        }
//        listener(nil, NSError(domain: "no docs", code: 1))
        return disposable
    }
    
    func setData(
        _ documentData: [String : Any],
        completion: ((Error?) -> Void)?
    ) {
        completion?(NSError(domain: "did not save", code: 1))
    }
    
    
}
