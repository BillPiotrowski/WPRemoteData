//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/15/21.
//

import Foundation
import SPCommon


// MARK: -
// MARK: ERROR DEFINITION
enum DatabaseInterfaceError: ScorepioError {
    case missingDocuments
    case missingData(
            dataType: String,
            path: String
         )
    case missingDocument(path: String)
    
    var message: String {
        switch self {
        case .missingDocuments: return "There were no documents returned from the server and no error was reported. Likely and error with Firebase."
        case .missingData(let dataType, let path): return "Could not initialize data type: \(dataType) because dictionary was empty from server at path: \(path)."
        case .missingDocument(let path): return "There was not a document returned from server and no error was provided for path: \(path)."
        }
    }
}
