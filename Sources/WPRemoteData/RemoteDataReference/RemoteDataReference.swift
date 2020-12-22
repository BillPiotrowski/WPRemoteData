//
//  RemoteDataTypeProtocol.swift
//  ServerData
//
//  Created by William Piotrowski on 6/16/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import SPCommon3

public protocol RemoteDataReferenceKnownType: RemoteDataReference {
    var readableRemoteDataType: ReadableRemoteData.Type { get }
}
extension RemoteDataReferenceKnownType {
    public func readableRemoteDataType(
        remoteDataDocument: RemoteDataDocument
    ) -> ReadableRemoteData.Type {
        return readableRemoteDataType
    }
}

/// Protocol describing a reference to data that exists on a remote server.
public protocol RemoteDataReference {
    var remoteDataLocation: RemoteDataLocation { get }
    var documentID: String { get }
    func readableRemoteDataType(
        remoteDataDocument: RemoteDataDocument
    ) -> ReadableRemoteData.Type
    
}

extension RemoteDataReference {
    // DEPRECATE AND SIMPLY USE readableRemoteDataType.init()
    private static func makeReadableRemoteDataFrom<T: ReadableRemoteData>(
        remoteDataDocument: RemoteDataDocument
        /*
        remoteDataType: Self,
        dictionary: [String: Any]
 */
    ) throws -> T {
        //let readableRemoteDataType = remoteDataDocument.remoteDataReference.readableRemoteDataType(remoteDataDocument: remoteDataDocument)
        return try T(remoteDataDocument: remoteDataDocument)
        //return try readableRemoteDataType.init(remoteDataDocument: remoteDataDocument)
        /*
        return try readableRemoteDataType.init(
            dictionary: remoteDataDocument.dictionary,
            remoteDataReference: remoteDataDocument.remoteDataReference
        )
 */
        /*
        let readableRemoteDataType = remoteDataType.readableRemoteDataType
        return try readableRemoteDataType.init(
            dictionary: dictionary,
            remoteDataReference: remoteDataType
        )
 */
    }
    
    // DEPRECATE AND SIMPLY USE readableRemoteDataType.init()
    public func makeReadableRemoteDataFrom<T: ReadableRemoteData>(
        remoteDataDocument: RemoteDataDocument
        //dictionary: [String: Any]
    ) throws -> T {
        /*
        return try Self.makeReadableRemoteDataFrom(
            remoteDataType: self,
            dictionary: dictionary
        )
 */
        return try Self.makeReadableRemoteDataFrom(
            remoteDataDocument: remoteDataDocument
        )
    }
}

extension RemoteDataReference {
    public var path: String {
        return documentReference.path
    }
}





