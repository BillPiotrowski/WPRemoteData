//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/17/21.
//

import Foundation
import FirebaseStorage

extension Storage: StorageInterface {
    func storageReferenceInterface() -> StorageReferenceInterface {
        return self.reference()
    }
    
    
}
