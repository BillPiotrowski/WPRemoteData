//
//  RemoteDataTypeDataFirestore.swift
//  ServerData
//
//  Created by William Piotrowski on 6/16/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import SPCommon
import FirebaseFirestore
import ReactiveSwift
import Promises


// RENAME TO REMOTE DATA LOCATION?

// MARK: FOLDER PROTOCOL
/// Protocol describing a remote server location where data can be referenced.
///
/// - warning: For effective database modeling, should use the Type specific version. This should only be used to describe Locations in an array or other abstract requirement.
public protocol RemoteDataLocation: RemoteDataItem {
    static var name: String { get }
    
    /// The optional parent. This would be used to generate the path. If no parent is set, collection will exist in the root directory.
    ///
    /// In the future, this could be generic, but not sure that is necessary. Would allow to traverse database more, but seems unnessary.
    var parentReference: RemoteDataDocument? { get }
    
}

// MARK: DEFAULT
extension RemoteDataLocation {
    public var parentReference: RemoteDataDocument? { nil }
}

// MARK: COMFORM: RemoteDataItem
extension RemoteDataLocation {
    public var name: String {
        Self.name
    }
    public var parentPathArray: [String] {
        parentReference?.pathArray ?? []
    }
}

// MARK: - DATABASE
extension RemoteDataLocation {
    internal static var database: DatabaseInterface {
        ServerAppStarter.shared.db
    }
}





// MARK: COLLECTION REF
extension RemoteDataLocation {
    /// Complete relative path (including name), separated by "/".
    ///
    /// Used to create Firebase `CollectionReference`.
    internal var path: String {
        return pathArray.joined(separator: "/")
    }
    
    /// The Firebase reference to the collection.
    ///
    /// Used to define the folder location.
    var collectionReferenceInterface: CollectionReferenceInterface {
        return Self.database.collectionInterface(path)
    }
}


// MARK: GENERATE ID
extension RemoteDataLocation {
    
    /// Generates a unique ID for the location without the need to send a server request.
    public func generateDocumentID() -> String {
        return collectionReferenceInterface.documentInterface().documentID
    }
}




