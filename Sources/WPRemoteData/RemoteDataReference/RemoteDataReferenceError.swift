//
//  RemoteDataReferenceError.swift
//  RemoteData
//
//  Created by William Piotrowski on 11/18/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import SPCommon3

enum RemoteDataReferenceError: ScorepioError {
    case documentDoesNotExist(serverDocument: RemoteDataReference)
    case noData(serverDocument: RemoteDataReference)
    case couldNotSaveLocallyNoFile(remoteData: RemoteDataReference)
    
    var message: String {
        switch self {
        case .documentDoesNotExist(let serverDocument): return "Document does not exist and no error was provided from Firebase. Query: \(serverDocument.documentReference.path)"
        case .noData(let serverDocument): return "Document snapshot contains no data: \(serverDocument.documentReference.path)"
        case .couldNotSaveLocallyNoFile(let remoteData): return "Could not save file \(remoteData.documentReference.path) locally because file is missing from server. Check accompanying error."
        }
    }
}
