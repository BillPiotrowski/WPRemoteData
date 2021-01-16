//
//  Batch.swift
//  RemoteData
//
//  Created by William Piotrowski on 11/25/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import FirebaseFirestore
import PromiseKit
import SPCommon

public struct WriteBatchScorepio {
    internal static let db = Firestore.firestore()
    internal let db = WriteBatchScorepio.db
    internal let batch: WriteBatchInterface
    public init(){
        let batch = db.batch()
        self.batch = batch
    }
}

// MARK: ADD TO BATCH
extension WriteBatchScorepio {
    public func setData(
        remoteDataReference: RemoteDataDocument,
        dictionary: [String: Any]
    ){
        batch.setDataInterface(
            dictionary,
            forDocument: remoteDataReference.documentReference
        )
    }
    public func setData<T: RemoteData>(
        writeableRemoteData: T
    ) where T: WriteableData {
        self.setData(
            remoteDataReference: writeableRemoteData.remoteDocument,
            dictionary: writeableRemoteData.dictionary
        )
    }
    
    public func updateData(
        remoteDataReference: RemoteDataDocument,
        dictionarySubset: [String: Any]
    ){
        batch.updateDataInterface(
            dictionarySubset,
            forDocument: remoteDataReference.documentReference
        )
    }
    
    public func deleteDocument(remoteDataReference: RemoteDataDocument){
        batch.deleteDocumentInterface(remoteDataReference.documentReference)
    }
    public func deleteDocument<Data: RemoteData>(
        remoteData: Data
    ){
        self.deleteDocument(
            remoteDataReference: remoteData.remoteDocument
        )
    }
}

// MARK: COMMIT
extension WriteBatchScorepio {
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
