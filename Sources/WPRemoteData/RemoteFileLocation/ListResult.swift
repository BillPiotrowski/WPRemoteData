//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/17/21.
//

import Foundation

// MARK: METHODS
public struct ListResult<
    RemoteFile: RemoteFileVariableChild,
    RemoteLocation: RemoteFileFolderGettableChildren
> {
    public let storageDocuments: [RemoteFile]
    public let error: Error?
    
    init(
        storageListResult: StorageListResultInterface,
        error: Error?,
        storageLocation: RemoteLocation
    ) where RemoteLocation == RemoteFile.RemoteLocation {
//        do {
            var storageDocuments: [RemoteFile] = []
            for item in storageListResult.itemInterfaces {
                let remoteFile = RemoteFile(
                    remoteLocation: storageLocation,
                    name: item.name
                )
//                let remoteFile = try  storageLocation.remoteFileType.init(
//                    remoteFileFolder: storageLocation,
//                    file: item.name
//                )
                storageDocuments.append(remoteFile)
            }
            self.storageDocuments = storageDocuments
            self.error = error
//        } catch {
//            self.storageDocuments = []
//            self.error = error
//        }
    }
}
