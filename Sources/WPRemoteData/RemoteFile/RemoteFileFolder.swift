//
//  RemoteFileFolder.swift
//  RemoteFile
//
//  Created by William Piotrowski on 6/29/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import Foundation
import SPCommon3
import FirebaseStorage
/*

public protocol RemoteFileFolderProtocol {
    var pathArray: [String] { get }
    var remoteFileType: RemoteFileProtocol.Type { get }
}

// MARK: DYN VARS
extension RemoteFileFolderProtocol {
    var path: String? {
        return (pathArray.count > 0 ) ? pathArray.joined(separator: "/") : nil
    }
}
*/
extension RemoteFileFolderProtocol {
    private var storage: Storage {
        return Storage.storage()
    }
    private var storageRef: StorageReference {
        return storage.reference()
    }
    var location: StorageReference {
        guard let path = path else {
            return storageRef
        }
        return storageRef.child(path)
    }
    public func list(completionHandler: @escaping (ListResult) -> Void){
        location.list(maxResults: 20, completion: { (result: StorageListResult, error: Error?) in
            completionHandler(ListResult(storageListResult: result, error: error, storageLocation: self))
        })
    }
}

// MARK: METHODS
//extension RemoteFileFolder {
    public struct ListResult {
        public let storageDocuments: [RemoteFileProtocol]
        public let error: Error?
        
        init(
            storageListResult: StorageListResult,
            error: Error?,
            storageLocation: RemoteFileFolderProtocol
        ){
            do {
                var storageDocuments: [RemoteFileProtocol] = []
                for item in storageListResult.items {
                    let remoteFile = try  storageLocation.remoteFileType.init(
                        remoteFileFolder: storageLocation,
                        file: item.name
                    )
                    storageDocuments.append(remoteFile)
                }
                self.storageDocuments = storageDocuments
                self.error = error
            } catch {
                self.storageDocuments = []
                self.error = error
            }
        }
    }
    
//}

