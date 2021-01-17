//
//  RemoteFileFolder.swift
//  RemoteFile
//
//  Created by William Piotrowski on 6/29/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import Foundation
import SPCommon
import Promises


public protocol RemoteFileFolderProtocol: RemoteDataItem {
    
    /// Optional parent `RemoteFileFolderProtocol`. If this is set, the path array is created by appending the name to the parent's path array. If not set, this will be a folder at the root.
    var parentFolder: RemoteFileFolderProtocol? { get }
    
    
    var remoteFileType: RemoteFileProtocol.Type { get }
}

// MARK: - CONFORM: RemoteDataItem
extension RemoteFileFolderProtocol {
    public var parentPathArray: [String] {
        parentFolder?.pathArray ?? []
    }
}

// MARK: - DEFAULT
extension RemoteFileFolderProtocol {
    public var parentFolder: RemoteFileFolderProtocol? { nil }
}

// MARK: DYN VARS
extension RemoteFileFolderProtocol {

    /// A String generated from the complete path array (folder name inclusive), separated by "/". There are no leading or trailing "/". Relative to root of storage.
    public var path: String? {
        return (pathArray.count > 0 ) ? pathArray.joined(separator: "/") : nil
    }
    
}


public protocol RemoteFileFolderGettableChildren: RemoteFileFolderProtocol {
    associatedtype VariableChild: RemoteFileVariableChild
}





extension RemoteFileFolderProtocol {
    internal var storage: StorageInterface {
        return ServerAppStarter.shared.storage
    }
    internal var storageReferenceInterface: StorageReferenceInterface {
        return storage.storageReferenceInterface()
    }
    var locationInterface: StorageReferenceInterface {
        guard let path = path else {
            return storageReferenceInterface
        }
        return storageReferenceInterface.childInterface(path)
    }
}

extension RemoteFileFolderGettableChildren where
    Self == VariableChild.RemoteLocation
{
    public func list(
        maxResults: Int64? = nil
    ) -> Promise<ListResult<VariableChild, Self>> {
        let maxResults = maxResults ?? 20
        return locationInterface.list(maxResults: maxResults)
        .then { result, error in
            ListResult(
                storageListResult: result,
                error: error,
                storageLocation: self
            )
        }
    }
}
