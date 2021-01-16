//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/14/21.
//

import Foundation
import FirebaseFirestore

// MARK: FIRESTORE SHARED PROTOCOL
/// A protocol defining the methods of a FirebaseQuery.
///
/// This is used to simulate the shared methods of `Query` and `CollectionReference` since the Firestore model has `CollectionReference` inheriting `Query`.
protocol FirebaseQuery: QueryInterface {
    func whereField(_ field: FieldPath, isEqualTo: Any) -> Query
    func whereField(_ field: FieldPath, isGreaterThan: Any) -> Query
    func whereField(_ field: FieldPath, isGreaterThanOrEqualTo: Any) -> Query
    func whereField(_ field: FieldPath, isLessThan: Any) -> Query
    func whereField(_ field: FieldPath, isLessThanOrEqualTo: Any) -> Query
    func getDocuments(completion: @escaping (QuerySnapshot?, Error?)-> Void)
    func addSnapshotListener(_ listener: @escaping (QuerySnapshot?, Error?)-> Void) -> ListenerRegistration
}

// Extends Query with FirebaseQuery to expose the relevant methods.
// Doing this to share the extension with CollectionReference.
extension Query: FirebaseQuery {
}



// MARK: -
// MARK: MAKES Query and CollectionReference CONFORM
extension FirebaseQuery {
    public func getDocumentsInterface(
        completion: @escaping (QuerySnapshotInterface?, Error?) -> Void) {
        return self.getDocuments(){ response,error  in
            completion(response,error)
        }
    }
    
    public func addSnapshotListenerInterface(
        _ listener: @escaping (QuerySnapshotInterface?, Error?)-> Void
    ) -> ListenerRegistrationInterface {
        addSnapshotListener(){ response,error  in
            listener(response, error)
        }
    }
    
    public func whereFieldInterface(
        _ fields: [String],
        isEqualTo: Any
    ) -> QueryInterface {
        let fieldPath = FieldPath(fields)
        return whereField(fieldPath, isEqualTo: isEqualTo)
    }
    
    public func whereFieldInterface(
        _ fields: [String],
        isGreaterThan: Any
    ) -> QueryInterface {
        let fieldPath = FieldPath(fields)
        return whereField(fieldPath, isGreaterThan: isGreaterThan)
    }
    
    public func whereFieldInterface(
        _ fields: [String],
        isGreaterThanOrEqualTo: Any
    ) -> QueryInterface {
        let fieldPath = FieldPath(fields)
        return whereField(fieldPath, isGreaterThanOrEqualTo: isGreaterThanOrEqualTo)
    }
    
    public func whereFieldInterface(
        _ fields: [String],
        isLessThan: Any
    ) -> QueryInterface {
        let fieldPath = FieldPath(fields)
        return whereField(fieldPath, isLessThan: isLessThan)
    }
    
    public func whereFieldInterface(
        _ fields: [String],
        isLessThanOrEqualTo: Any
    ) -> QueryInterface {
        let fieldPath = FieldPath(fields)
        return whereField(fieldPath, isLessThanOrEqualTo: isLessThanOrEqualTo)
    }
}




// MARK: -
// MARK: QuerySnapshotInterface
extension QuerySnapshot: QuerySnapshotInterface {
    public var documentsInterface: [DocumentSnapshotInterface] {
        return documents
    }
}

// MARK: -
// MARK: ListenerRegistrationInterface
public typealias ListenerRegistrationInterface = ListenerRegistration
