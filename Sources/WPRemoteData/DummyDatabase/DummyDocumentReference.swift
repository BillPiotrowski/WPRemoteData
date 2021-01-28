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
    
    func delete(completion: ((Error?) -> Void)?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            completion?(nil)
        }
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


struct DummyDocumentSnapshot: DocumentSnapshotInterface {
    let documentID: String
    let dataVal: [String: Any]?
    
    func data() -> [String : Any]? {
        dataVal
    }
}

extension DummyDocumentReference {
    func getDocumentInterface(
        completion: @escaping (DocumentSnapshotInterface?, Error?) -> Void
    ) {
        if let dictionary = self.dictionaries[documentID] {
            let snapshot = DummyDocumentSnapshot(
                documentID: self.documentID,
                dataVal: dictionary
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                completion(snapshot, nil)
            }
        } else {
            switch documentID {
            case DummyDataDocID.failure.rawValue:
                let error = NSError(domain: "no doc", code: 1)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    completion(nil, error)
                }
            default:
                let snapshot = DummyDocumentSnapshot(
                    documentID: self.documentID,
                    dataVal: ["propert1":"value1"]
                )
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    completion(snapshot, nil)
                }
            }
        }
    }
    var dictionaries: [String: [String: Any]] {
        return ServerAppStarter.shared.testDataDictionaries
    }
}

enum DummyDataDocID: String {
    case quickSuccess
    case failure
    
}


