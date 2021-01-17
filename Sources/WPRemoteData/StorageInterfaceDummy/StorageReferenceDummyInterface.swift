//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/17/21.
//

import Foundation


class DummyStorageReferenceInterface: StorageReferenceInterface {
    
    let name: String
    let path: String
    init(
        name: String,
        path: String
    ){
        self.name = name
        self.path = path
    }
}
    
extension DummyStorageReferenceInterface {
    func childInterface(_ path: String) -> StorageReferenceInterface {
        return DummyStorageReferenceInterface(
            name: "",
            path: "\(self.path)/\(name)/\(path)"
        )
    }
    
    func listInterface(
        maxResults: Int64,
        completion: @escaping (StorageListResultInterface, Error?) -> Void)
    {
        completion(
            DummyStorageListResult(
                itemInterfaces: []
            ),
            NSError(domain: "No results", code: 3)
        )
    }
    
    func writeInterface(
        toFile fileURL: URL,
        completion: ((URL?, Error?) -> Void)?
    ) -> StorageDownloadTaskInterface {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion?(nil, NSError(domain: "error writing", code: 4))
        }
        return DummyStorageDownloadTask()
        
    }
    
    
}
