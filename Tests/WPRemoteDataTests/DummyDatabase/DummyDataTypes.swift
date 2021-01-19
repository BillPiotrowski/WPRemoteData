//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/14/21.
//

import Foundation
import SPCommon
@testable import WPRemoteData

// MARK: -
// MARK: REMOTE LOCATION
struct TestLocation {
    
}
extension TestLocation: RemoteDataLocation {
    public static let name = "testCollection"
    
//    func makeRemoteDataReference(
//        document: RemoteDataDocument
//    ) -> RemoteDataReference {
//        return TestDocument(testDataID: document.documentID)
//    }
    
}

extension TestLocation: RemoteDataLocationVariableChild {
    typealias A = TestDocument
    
    
}

// MARK: -
// MARK: DOCUMENT
struct TestDocument {
    let testDataID: String
}
extension TestDocument: RemoteDataDocument {
    var documentID: String { testDataID }
    
    
//    func readableRemoteDataType(
//        remoteDataDocument: RemoteDataDocument
//    ) -> ReadableRemoteData.Type {
//        TestData.self
//    }
}
extension TestDocument: GettableRemoteDataDocument {
    typealias Data = TestData
    
    var location: TestLocation {
        TestLocation()
    }
    init(location: TestLocation, documentID: String){
        self.init(testDataID: documentID)
    }
}
extension TestDocument: RemoteDataDownloadableDocument {
    
    var localDocument: TestLocalFile {
        TestLocalFile(dummyID: self.testDataID)
    }
}



// MARK: - LOCAL
struct TestLocalFolder: LocalDirectory {
    let name: String = "tests"
}
//extension DummyLocalFolder: LocalDirectoryGe

struct TestLocalFile: LocalFile {
    let dummyID: String
    var directory: LocalDirectory = TestLocalFolder()
    
    var name: String { dummyID }
}
extension TestLocalFile: LocalFileGeneric {
    var localDirectoryGeneric: TestLocalFolder {
        TestLocalFolder()
    }
    init(localDirectory: TestLocalFolder, name: String) {
        self.init(dummyID: name)
    }
}
extension TestLocalFile: LocalFileOpenable  {
    typealias O = TestData
}




// MARK: -
// MARK: DATA
struct TestData {
    let testDataID: String
    
}
extension TestData {
//    init(remoteDataDocument: RemoteDataDocument) throws {
//        self.init(testDataID: remoteDataDocument.documentID)
//    }
    
    init(dictionary: [String : Any]) throws {
        guard let testDataID = dictionary["testDataID"] as? String
        else { throw NSError(domain: "No ID", code: 1) }
        self.init(testDataID: testDataID)
    }
    
    
    
}

// As long as it's writeable, this data can save.
extension TestData: WriteableData {
    var dictionary: [String : Any] {
        return [:]
    }
}
extension TestData: RemoteData {
    init(
        remoteDocument: TestDocument,
        dictionary: [String : Any]
    ) throws {
        self.init(testDataID: remoteDocument.testDataID)
    }
    
    var remoteDocument: TestDocument {
        TestDocument(testDataID: testDataID)
    }
    
}
extension TestData: LocalOpenable, LocalOpenableData {
    var localFile: TestLocalFile { TestLocalFile(dummyID: testDataID) }
    
    /// Used to instantiate self (LocalOpenable) from a local file reference (LocalFile).
    init(localFile: TestLocalFile) throws {
        self.init(testDataID: localFile.dummyID)
    }
    
}
