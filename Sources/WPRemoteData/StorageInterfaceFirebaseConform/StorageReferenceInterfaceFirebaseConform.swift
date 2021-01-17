//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/17/21.
//

import Foundation
import FirebaseStorage

extension StorageReference: StorageReferenceInterface {
    public func writeInterface(
        toFile fileURL: URL,
        completion: ((URL?, Error?) -> Void)?
    ) -> StorageDownloadTaskInterface {
        self.write(toFile: fileURL, completion: completion)
    }
    
    
    public func listInterface(
        maxResults: Int64,
        completion: @escaping (StorageListResultInterface, Error?) -> Void
    ) {
        self.list(maxResults: maxResults, completion: completion)
    }
    
    public func childInterface(_ path: String) -> StorageReferenceInterface {
        return self.child(path)
    }
    
}
