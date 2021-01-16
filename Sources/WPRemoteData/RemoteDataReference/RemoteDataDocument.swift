//
//  RemoteDataTypeProtocol.swift
//  ServerData
//
//  Created by William Piotrowski on 6/16/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import SPCommon
import FirebaseFirestore
import PromiseKit
import ReactiveSwift
import Promises

/// Protocol describing a reference to data that exists on a remote server.
///
/// - warning: To effectively model the database, this protocol should not be used directly. Instead, use Generics version the specifies type. This protocol should be used to descripe and array of document references and still maintains the minimal functionality.
public protocol RemoteDataDocument: RemoteDataItem {
    
    /// The identifier for the document.
    ///
    /// For consistenty with Local, might change this to `name`.
    var documentID: String { get }
    
    /// Location of the Document on the server. Abstract protocol and not a generic.
    var remoteDataLocationProtocol: RemoteDataLocation { get }
    
    
    
}


// MARK: -
// MARK: CONFORM: RemoteDataItem
extension RemoteDataDocument {
    public var parentPathArray: [String] {
        remoteDataLocationProtocol.pathArray
    }
    public var name: String { documentID }
}


extension RemoteDataDocument {
    public var path: String {
        return documentReference.path
    }
}

// MARK: - DEFINE DOC REF
extension RemoteDataDocument {
    var documentReference: DocumentReferenceInterface { remoteDataLocationProtocol.collectionReferenceInterface.documentInterface(
            documentID
        )
    }
}



// MARK: - TIMESTAMP CONVERT
extension RemoteDataDocument {
    static func convert(rawTime: Any) -> Date? {
        guard let timestamp = rawTime as? Timestamp else { return nil }
        return timestamp.dateValue()
    }
    static func convert(date: Date) -> Timestamp {
        return Timestamp(date: date)
    }
}

// MARK: TIMESTAMP ALIAS
public typealias ServerTimestamp = Timestamp

// MARK: - SAVE PROMISE
extension RemoteDataDocument {
    /// Save to remote document.
    public func save(dictionary: [String:Any]) -> Promises.Promise<Void>{
        self.documentReference.save(dictionary: dictionary)
    }
}
