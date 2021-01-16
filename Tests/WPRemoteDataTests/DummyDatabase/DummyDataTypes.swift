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
// MARK: LOCATION
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
extension TestLocation {
    static var database: DatabaseInterface { DummyDatabase.shared }
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
