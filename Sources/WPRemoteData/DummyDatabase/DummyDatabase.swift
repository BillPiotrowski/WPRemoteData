//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/14/21.
//

import Foundation

// MARK: DATABASE
class DummyDatabase {
    static let shared = DummyDatabase()
    private var collectionReferences: [String: DummyCollectionReference] = [:]

    private init() {
    }
}
extension DummyDatabase: DatabaseInterface {
    func collectionInterface(_ path: String) -> CollectionReferenceInterface {
        guard let collection = collectionReferences[path]
        else {
            let newCollection = DummyCollectionReference(path: path)
            self.collectionReferences[path] = newCollection
            return newCollection
        }
        return collection
    }
}




// MARK: -
// MARK: DISPOSABLE
class DummyDisposable: NSObject {
    private let removeCallback: ()->Void
    init(removeCallback: @escaping ()->Void){
        self.removeCallback = removeCallback
    }
}
extension DummyDisposable: ListenerRegistrationInterface {
    func remove() {
        self.removeCallback()
    }
}

