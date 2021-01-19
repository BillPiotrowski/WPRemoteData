//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/18/21.
//

@testable import WPRemoteData
import SPCommon
import Foundation

struct DummyRemoteFileFolder: RemoteFileFolderProtocol {
    var remoteFileType: RemoteFileProtocol.Type = DummyRemoteFile.self
    
    let name: String = "tests"
    
    
}

struct DummyLocalFolder: LocalDirectory {
    let name: String = "tests"
}
//extension DummyLocalFolder: LocalDirectoryGe

struct DummyLocalFile: LocalFile {
    let dummyID: String
    var directory: LocalDirectory = DummyLocalFolder()
    
    var name: String { dummyID }
}
extension DummyLocalFile: LocalFileGeneric {
    var localDirectoryGeneric: DummyLocalFolder {
        DummyLocalFolder()
    }
    init(localDirectory: DummyLocalFolder, name: String) {
        self.init(dummyID: name)
    }
}
extension DummyLocalFile: LocalFileOpenable {
    typealias O = DummyLocalData
}

struct DummyLocalData {
    let dummyID: String
}
extension DummyLocalData: LocalOpenableData {
    init(localFile: DummyLocalFile) throws {
        self.init(dummyID: localFile.dummyID)
    }
    
    var localFile: DummyLocalFile {
        DummyLocalFile(dummyID: dummyID)
    }
    init(dictionary: [String : Any]) throws {
        throw NSError(domain: "cant init dummy data", code: 2)
    }
    var dictionary: [String : Any] {
        ["dummyID":dummyID]
    }
}

struct DummyRemoteFile: RemoteFileProtocol {
    let dummyID: String
    let location: RemoteFileFolderProtocol = DummyRemoteFileFolder()
    var name: String { dummyID }
    
    var localFile: LocalFile { DummyLocalFile(dummyID: dummyID) }
}
