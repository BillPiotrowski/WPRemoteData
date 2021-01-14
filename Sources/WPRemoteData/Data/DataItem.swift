//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/13/21.
//

import Foundation

public protocol RemoteDataItem {
    
    /// The name of the collection or reference.
    var name: String { get }
    
    /// The path array of the parent collection or parent reference.
    ///
    /// Does not include the name of this element, but does include the name of the parent.
    ///
    /// This is relative to the root, so if it is a collection at the root, the path array will be `[]`.
    var parentPathArray: [String] { get }
}

extension RemoteDataItem {
    /// The full path array, including the collection or reference name as the last element.
    public var pathArray: [String] {
        var pathArray = parentPathArray
        pathArray.append(name)
        return pathArray
    }
}
