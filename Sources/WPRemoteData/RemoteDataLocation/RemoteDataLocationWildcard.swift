//
//  RemoteDataLocationWildcard.swift
//  RemoteData
//
//  Created by William Piotrowski on 11/18/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

// This logic was built, but seems unneccesary because there will never be unknown data from the server. Whereas local files can be unknown – especially when calculating sizes. Local files can be recursive through folders, where Firebase cannot.


/*
import Foundation
import SPCommon

// MARK: GET WILDCARDS
extension RemoteDataLocation {
    
    /// Creates and returns an array of wildcard variables. Wildcard array is in order of appearance in array from left to right. Throws if the length or structure does not match.
    /// - Parameters:
    ///   - dummyPathArray: A model path array with all variables replaced with wildcards.
    ///   - pathArray: the path array to test if it matches the structure of the model path array.
    static func getWildcardVariables(
        dummyPathArray: [String],
        pathArray: [String]
    ) throws -> [String] {
        let length = dummyPathArray.count
        guard length == pathArray.count
            else { throw LocalFilePathArrayError.lengthsDontMatch }
        var wildcards = [String]()
        for i in 0..<length {
            if dummyPathArray[i] == Self.wildcard {
                wildcards.append(pathArray[i])
                continue
            }
            guard dummyPathArray[i] == pathArray[i]
                else {
                    throw LocalFilePathArrayError.structureDoesntMatch
            }
        }
        print("WILDCARDS: \(wildcards)")
        return wildcards
    }
    
    public func getWildcardVariables(
        withPathArray: [String]
    ) throws -> [String] {
        return try Self.getWildcardVariables(
            dummyPathArray: self.pathArray,
            pathArray: withPathArray
        )
    }
    static var wildcard: String { return "*" }
    
    
}
*/
