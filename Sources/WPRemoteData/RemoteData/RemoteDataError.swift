//
//  RemoteDataError.swift
//  RemoteData
//
//  Created by William Piotrowski on 11/18/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import SPCommon

public enum RemoteDataError: ScorepioError {
    case couldNotConvertToSelf(type: ReadableRemoteData.Type)
    case initializeFailFromServerDoc(type: ReadableRemoteData.Type)
    case initIncorrectRemoteDataReferenceType(
        readableRemoteDataType: ReadableRemoteData.Type,
        expectedRemoteDataReference: RemoteDataReference.Type,
        receivedRemoteDataReference: RemoteDataReference
    )
    case initIncorrectRemoteDataReference(
        readableRemoteDataType: ReadableRemoteData.Type,
        expectedRemoteDataReference: RemoteDataReference,
        receivedRemoteDataReference: RemoteDataReference
    )
    
    public var message: String {
        switch self {
        case .couldNotConvertToSelf(let type): return "Could not convert one or more of the firestore documents to its native type: \(type)."
        case .initializeFailFromServerDoc(let type): return "Could not initialize data type: \(type) from server doc and dictionary."
        case .initIncorrectRemoteDataReferenceType(let vars):
            return "Could not initialize type: \(vars.readableRemoteDataType) because it receiced a remoteDataReference: \(vars.receivedRemoteDataReference), but expected type: \(vars.expectedRemoteDataReference)."
        case .initIncorrectRemoteDataReference(let vars):
            return "Could not initialize type: \(vars.readableRemoteDataType) because it receiced a remoteDataReference: \(vars.receivedRemoteDataReference), but expected: \(vars.expectedRemoteDataReference)."
        }
    }
}
