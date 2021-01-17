//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/17/21.
//

import Foundation
import FirebaseStorage

extension StorageListResult: StorageListResultInterface {
    public var itemInterfaces: [StorageReferenceInterface] {
        return self.items
    }
    
    
}
