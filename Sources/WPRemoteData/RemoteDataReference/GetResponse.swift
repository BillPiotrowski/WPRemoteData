//
//  GetResponse.swift
//  RemoteData
//
//  Created by William Piotrowski on 11/18/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//
/*
import SPCommon
import FirebaseFirestore

// REPLACE ADD LISTENER WITH REACTIVE SWIFT AND DEPRECATE GetResponse!!

// MARK: REMOTE DATA RESPONSE
//extension RemoteDataType {
    internal struct GetResponse {
        public let document: ReadableRemoteData?
        public let error: Error?
        init(document: ReadableRemoteData?, error: Error?){
            self.document = document
            self.error = error
        }
                
       init(
           documentSnapshot: DocumentSnapshot?,
           error: Error?,
           remoteDataProtocol: RemoteDataReference
       ){
        do {
            guard let documentSnapshot = documentSnapshot
                else { throw RemoteDataReferenceError.documentDoesNotExist(
                    serverDocument: remoteDataProtocol
                )
            }
            let serverDoc = RemoteDataDocument(
                document: documentSnapshot,
                folder: remoteDataProtocol.remoteDataLocation
            )
            /*
            guard let dictionary = documentSnapshot.data()
                else { throw FirestoreError2.noData(
                    serverDocument: remoteDataProtocol
                )
            }
            
            */
            let document = try serverDoc.makeReadableRemoteData()
            /*
               let document = try remoteDataProtocol.makeReadableRemoteDataFrom(
                   dictionary: dictionary
               )
 */
               /*
               let document =
                   try RemoteDataType.makeReadableRemoteDataFrom(
                   remoteDataType: remoteDataProtocol,
                   documentSnapshot: documentSnapshot
               )
*/
               self.init(document: document, error: nil)
           } catch {
               self.init(document: nil, error: error)
           }
       }
}
*/
