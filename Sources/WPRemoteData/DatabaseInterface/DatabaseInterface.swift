//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/13/21.
//

import Foundation


/// A protocol defining a remote database.
///
/// Used to model Firestore database and allow for injection testing.
public protocol DatabaseInterface {
    func collectionInterface(_ path: String) -> CollectionReferenceInterface
}


