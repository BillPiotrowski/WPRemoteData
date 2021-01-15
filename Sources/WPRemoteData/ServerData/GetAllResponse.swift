//
//  GetAllResponse.swift
//  Scorepio
//
//  Created by William Piotrowski on 7/4/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import FirebaseFirestore
import PromiseKit

// MAY DEPRECATE, but leaving in case there is use for a container to compare changes when listening to a folder.
/*
// MARK: RESPONSE
//extension RemoteDataFolderProtocol {
    public struct GetAllResponse {
        public let documents: [ReadableRemoteData]
        public let error: Error?
        
        init(documents: [ReadableRemoteData], error: Error?){
            self.documents = documents
            self.error = error
        }
        
        public init(
            querySnapshot: QuerySnapshotInterface?,
            error: Error?,
            serverLocation: RemoteDataLocation
        ){
            
            guard let querySnapshot = querySnapshot else {
                self.init(documents: [], error: error ?? RemoteDataLocationError.missingQuerySnapshot)
                return
            }
            
            //var documentArray: [ReadableRemoteDataProtocol] = []
            let initializingError: RemoteDataLocationError? = nil
            // SEEMS SIMILAR TO METHOD IN REMOTE DATA
            //for document in querySnapshot.documents {
                /*
                let serverDocument = RemoteDataType(
                    serverLocation: serverLocation,
                    documentID: document.documentID
                )
                let dictionary = document.data()
 */
                do {
                    let documentArray = try serverLocation.makeReadableRemoteDataFrom(querySnapshot: querySnapshot)
                    //guard
                    /*
                        let docType = try serverDocument.readableRemoteDataType(
                            dictionary: dictionary
                        )//,
                        let doc = try docType.init(
                            dictionary: dictionary,
                            serverDocument: serverDocument
                        )
 */
                    /*
                        else {
                        initializingError = RemoteDataFolder.FirestoreError.couldNotInitializeData
                        break
                    }
 */
                    //documentArray.append(serverDocument)
                    self.init(documents: documentArray, error: error ?? initializingError)
                } catch {
                    self.init(documents: [], error: error)
                }
            //}
        }
    }
//}
/*
extension GetAllResponse: TaskReturn {
    var returnItem: Any? {
        return self.documents
    }
}
 */
 
*/
