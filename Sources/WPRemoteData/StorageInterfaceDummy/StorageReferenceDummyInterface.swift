//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/17/21.
//

import Foundation


class DummyStorageReferenceInterface: StorageReferenceInterface {
    
    let path: String
    init(
        path: String
    ){
        self.path = path
    }
    
    var name: String {
        let pathArray = path.split(separator: "/")
        guard let last = pathArray.last
        else { return path }
        return String(last)
    }
}
    
extension DummyStorageReferenceInterface {
    func childInterface(_ path: String) -> StorageReferenceInterface {
        return DummyStorageReferenceInterface(
            path: "\(self.path)/\(path)"
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
        print("PATH: \(self.path)")
        switch self.name {
        case FileName.error.rawValue: return DummyErrorDownloadTask()
        case FileName.simpleSuccess.rawValue: return DummySuccessDownloadTask()
        default: return DummyErrorDownloadTask()
        }
        
        
    }
    
    enum FileName: String {
        case error
        case simpleSuccess
    }
    
}



/*
 Test make sure the initial value is sent / recieved (this is more verifying signal producer properties.
 Test that pausing ends the signal.
 Test error stops signal.
 Test complete stops signal and recieves final progress.
 test progress behaves as expected (as child of main progress)
 
 
 
 */


