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
        switch self.name {
        case TestRemoteFileName.error.rawValue:
            return DummyErrorDownloadTask()
        case TestRemoteFileName.simpleSuccess.rawValue:
            return DummySuccessDownloadTask()
        case TestRemoteFileName.simpleSuccess2.rawValue:
            return DummySuccessDownloadTask()
        default: return DummyErrorDownloadTask()
        }
        
        
    }
    
}


enum TestRemoteFileName: String {
    case error
    case simpleSuccess
    case simpleSuccess2
}


/*
 Test make sure the initial value is sent / recieved (this is more verifying signal producer properties.
 Test that pausing ends the signal.
 Test error stops signal.
 Test complete stops signal and recieves final progress.
 test progress behaves as expected (as child of main progress)
 
 
 
 */


