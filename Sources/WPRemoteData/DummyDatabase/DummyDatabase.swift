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


// MARK: -
// MARK: CONFORM: DatabaseInterface
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
// MARK: TESTING HELPERS
extension DummyDatabase {
    /// Unit tests seem to retain same Database between tests. Reset allows opportunity to reset stored collections and set to empty.
    func reset(){
        for (key, ref) in self.collectionReferences {
            ref.reset()
        }
        self.collectionReferences = [:]
    }
}

