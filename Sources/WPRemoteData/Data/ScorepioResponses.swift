//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/14/21.
//

import Foundation


// MARK: -
// MARK: Query


/// Container for query response from server.
///
/// - note: Made this a struct instead of sending the raw array of documents or data so that more information could be included in the future.
///
/// Firebase sends back more information that is currently not modeled, but could be in the future. This struct allows for easily adding new properties and methods.
///
/// Could also attempt to lazily render the data or documents in the future so only what is required gets generated.
public struct ScorepioQueryResponse<
    T: RemoteDataDocument,
    D: RemoteData
> {
    public let documents: [ScorepioDocumentResponse<T,D>]
}
extension ScorepioQueryResponse {
    /// An array of just the document Data elements extracted from their respective `ScorepioDocumentRespose`s.
    public var dataArray: [D] {
        return documents.map { doc -> D in
            doc.data
        }
    }
}


// MARK: -
// MARK: Document

/// Container for single document response from server.
///
/// - note: Made this a struct instead of sending the raw array of documents or data so that more information could be included in the future.
///
/// Firebase sends back more information that is currently not modeled, but could be in the future. This struct allows for easily adding new properties and methods.
///
/// Could also attempt to lazily render the data or documents in the future so only what is required gets generated.
public struct ScorepioDocumentResponse<
    T: RemoteDataDocument,
    D: RemoteData
> {
    public let reference: T
    public let data: D
}
