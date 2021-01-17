//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/17/21.
//

import Foundation
import Promises

public protocol StorageReferenceInterface {
    var name: String { get }
    func childInterface(_ path: String) -> StorageReferenceInterface
    func listInterface(
        maxResults: Int64,
        completion: @escaping (StorageListResultInterface, Error?) -> Void
    )
    func writeInterface(
        toFile fileURL: URL,
        completion: ((URL?, Error?) -> Void)?
    ) -> StorageDownloadTaskInterface
}

extension StorageReferenceInterface {
    func list(
        maxResults: Int64
    ) -> Promise<(StorageListResultInterface, Error?)>{
        return Promise { fulfill, reject in
            self.listInterface(
                maxResults: maxResults
            ) { result, error in
                fulfill((result, error))
            }
        }
    }
}
