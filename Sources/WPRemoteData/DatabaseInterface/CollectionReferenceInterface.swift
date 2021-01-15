//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/14/21.
//

import Foundation

/// A protocol defining a remote database collection reference.
///
/// Points to a specific folder in the database.
///
/// Used to model Firestore database and allow for injection testing.
public protocol CollectionReferenceInterface: QueryInterface {
    func documentInterface() -> DocumentReferenceInterface
    
    
    /// Gets a `FIRDocumentReference` referring to the document at the specified path, relative to this collection's own path.
    /// - Parameter documentPath: The slash-separated relative path of the document for which to get a `FIRDocumentReference`.
    func documentInterface(
        _ documentPath: String
    ) -> DocumentReferenceInterface
    
    var path: String { get }
}




