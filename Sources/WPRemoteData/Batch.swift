//
//  Batch.swift
//  RemoteData
//
//  Created by William Piotrowski on 11/25/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import FirebaseFirestore
import PromiseKit

public struct WriteBatch {
    internal static let db = Firestore.firestore()
    internal let db = WriteBatch.db
    internal let batch = db.batch()
    public init(){
    }
}

// MARK: ADD TO BATCH
extension WriteBatch {
    public func setData(
        remoteDataReference: RemoteDataReference,
        dictionary: [String: Any]
    ){
        batch.setData(
            dictionary,
            forDocument: remoteDataReference.documentReference
        )
    }
    public func setData(
        writeableRemoteData: WriteableRemoteData
    ){
        self.setData(
            remoteDataReference: writeableRemoteData.remoteDataReference,
            dictionary: writeableRemoteData.dictionary
        )
    }
    
    public func updateData(
        remoteDataReference: RemoteDataReference,
        dictionarySubset: [String: Any]
    ){
        batch.updateData(
            dictionarySubset,
            forDocument: remoteDataReference.documentReference
        )
    }
    
    public func deleteDocument(remoteDataReference: RemoteDataReference){
        batch.deleteDocument(remoteDataReference.documentReference)
    }
    public func deleteDocument(remoteData: RemoteData){
        self.deleteDocument(
            remoteDataReference: remoteData.remoteDataReference
        )
    }
}

// MARK: COMMIT
extension WriteBatch {
    public func commit() -> Promise<Void> {
        return Promise { seal in
            batch.commit() { error in
                guard let error = error
                    else {
                        seal.fulfill(())
                        return
                }
                seal.reject(error)
            }
        }
    }
}
