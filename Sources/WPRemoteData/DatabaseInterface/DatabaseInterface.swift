//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/13/21.
//

import Foundation
import FirebaseFirestore
import PromiseKit



//class DBSwitcher {
//    
//    // MARK: - Properties
//
//    private static var sharedNetworkManager: NetworkManager = {
//        let networkManager = NetworkManager(baseURL: API.baseURL)
//
//        // Configuration
//        // ...
//
//        return networkManager
//    }()
//
//    // MARK: -
//
//    let database: DatabaseInterface
//
//    // Initialization
//
//    private init(database: DatabaseInterface? = nil) {
//        let database = database ?? Firestore.firestore()
//        self.baseURL = baseURL
//    }
//
//    // MARK: - Accessors
//
//    class func shared() -> NetworkManager {
//        return sharedNetworkManager
//    }
//}



public protocol DatabaseInterface {
    func collectionInterface(_ path: String) -> CollectionReferenceInterface
}


extension Firestore: DatabaseInterface {
    public func collectionInterface(_ collectionPath: String) -> CollectionReferenceInterface {
        return self.collection(collectionPath)
    }
}





// MARK: LOCATION / COLLECTION

public protocol CollectionReferenceInterface: QueryInterface {
    func documentInterface() -> DocumentReferenceInterface
    
    
    /// Gets a `FIRDocumentReference` referring to the document at the specified path, relative to this collection's own path.
    /// - Parameter documentPath: The slash-separated relative path of the document for which to get a `FIRDocumentReference`.
    func documentInterface(
        _ documentPath: String
    ) -> DocumentReferenceInterface
    
//    func getAll(
////        remoteDataTypeFolder: RemoteDataLocation,
//        filters: [WhereFilter]?
//    ) -> Promise<[ReadableRemoteData]> //{
        //print("GET ALL 3.1")
//        let collectionReference = remoteDataTypeFolder.collectionReference
//        let query = Self.makeQueryFrom(
//            collectionReference: collectionReference,
//            filters: filters
//        )
//        return Self.getAll(
//            query: query,
//            remoteDataLocation: remoteDataTypeFolder
//        )
//    }
    
}
extension CollectionReferenceInterface {
    var temp: String {
        self.getDocumentsInterface(){ _, _ in
            
        }
        return "asdasdf"
        
    }
}
extension CollectionReference: CollectionReferenceInterface {
    public func documentInterface(
        _ documentPath: String
    ) -> DocumentReferenceInterface {
        self.document(documentPath)
    }
    
    public func documentInterface() -> DocumentReferenceInterface {
        self.document()
    }
}

//struct DummyDatabaseLocation {
//    
//}
//extension DummyDatabaseLocation: CollectionReferenceInterface {
//    func documentInterface() -> DocumentReferenceInterface {
//        DummyDatabaseDocument()
//    }
//}










// MARK: QUERY SNAPSHOT
public protocol QuerySnapshotInterface {
    var documentsInterface: [DocumentSnapshotInterface] { get }
}
extension QuerySnapshot: QuerySnapshotInterface {
    public var documentsInterface: [DocumentSnapshotInterface] {
        return documents
    }
    
    
}



