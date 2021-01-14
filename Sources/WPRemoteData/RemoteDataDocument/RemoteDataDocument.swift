//
//  RemoteDataDocument.swift
//  Scorepio
//
//  Created by William Piotrowski on 7/4/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import FirebaseFirestore

// BETTER NAME
// RemoteDataResult ??
// MARK: DICTIONARY??? BAD NAME
public struct RemoteDataDocument {
    private let document: DocumentSnapshotInterface
    public let folder: RemoteDataLocation
    
    init(
        document: DocumentSnapshotInterface,
        folder: RemoteDataLocation
    ){
        self.document = document
        self.folder = folder
    }
    
    public var dictionary: [String: Any] {
        return document.data() ?? [:]
    }
    public var documentID: String {
        return document.documentID
    }
    public func makeReadableRemoteData(
    ) throws -> ReadableRemoteData {
        return try folder.makeReadableRemoteDataFrom(document: self)
        
        // Alternative:
        /*
        return try remoteDataReference.readableRemoteDataType.init(
            dictionary: dictionary,
            serverDocument: remoteDataReference
        )
        */
    }
    
    // Not currently using, but could be useful?
    public var remoteDataReference: RemoteDataReference {
        return folder.makeRemoteDataReference(document: self)
    }
}
