//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/17/21.
//

import Foundation

class DummyStorage: StorageInterface {
    func storageReferenceInterface() -> StorageReferenceInterface {
        return DummyStorageReferenceInterface(path: "root")
    }
}

