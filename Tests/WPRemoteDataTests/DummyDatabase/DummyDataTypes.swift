//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/14/21.
//

import Foundation
@testable import WPRemoteData

// MARK: -
// MARK: LOCATION
struct TestLocation {
    
}
extension TestLocation: RemoteDataLocation {
    public static let name = "testCollection"
    
    func makeRemoteDataReference(
        document: RemoteDataDocument
    ) -> RemoteDataReference {
        return TestDocument(testDataID: document.documentID)
    }
    
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
extension TestDocument: RemoteDataReference {
    var documentID: String { testDataID }
    
    
    func readableRemoteDataType(
        remoteDataDocument: RemoteDataDocument
    ) -> ReadableRemoteData.Type {
        TestData.self
    }
}
extension TestDocument: RemoteDataReferenceGeneric {
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
extension TestData: ReadableRemoteData {
    init(remoteDataDocument: RemoteDataDocument) throws {
        self.init(testDataID: remoteDataDocument.documentID)
    }
    
    init(dictionary: [String : Any]) throws {
        guard let testDataID = dictionary["testDataID"] as? String
        else { throw NSError(domain: "No ID", code: 1) }
        self.init(testDataID: testDataID)
    }
    
    var dictionary: [String : Any] {
        return [:]
    }
    
    var remoteDataReference: RemoteDataReference {
        return TestDocument(testDataID: testDataID)
    }
    
    
}
extension TestData: RemoteDataGeneric {
    init(
        remoteDataReference: TestDocument,
        dictionary: [String : Any]
    ) throws {
        self.init(testDataID: remoteDataReference.testDataID)
    }
    
    var reference: TestDocument {
        TestDocument(testDataID: testDataID)
    }
    
}
