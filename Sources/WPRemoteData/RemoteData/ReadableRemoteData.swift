//
//  ReadableRemoteData.swift
//  Scorepio
//
//  Created by William Piotrowski on 3/6/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import PromiseKit
import ReactiveSwift
import Firebase
import SPCommon

public protocol ReadableRemoteData: ReadableData, WriteableData, RemoteData {
    init(remoteDataDocument: RemoteDataDocument) throws
}



// STILL USED FOR LISTENER. REPLACE
// MARK: HELPER FUNCTIONS
extension ReadableRemoteData {
    /*
    internal static func createGetResponse(result: GetResponse) -> (firestoreDoc: Self?, error: Error?) {
        guard let doc = result.document as? Self else {
            return (nil, result.error ?? RemoteDataError.couldNotConvertToSelf(type: Self.self))
        }
        return (firestoreDoc: doc, error: result.error)
    }
    */
    internal static func createGetAllResponse(result: GetAllResponse) -> (firestoreDocs: [Self], error: Error?) {
        var returnArray: [Self] = []
        var convertingError: RemoteDataError? = nil
        
        for firestoreDoc in result.documents {
            guard let doc = firestoreDoc as? Self else {
                convertingError = RemoteDataError.couldNotConvertToSelf(type: Self.self)
                break
            }
            returnArray.append(doc)
        }
        return(returnArray, result.error ?? convertingError)
    }
}












