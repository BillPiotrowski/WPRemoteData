//
//  ReadableRemoteData.swift
//  Scorepio
//
//  Created by William Piotrowski on 3/6/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import PromiseKit
import ReactiveSwift
import Firebase
import SPCommon
import Promises



/// Defines `ReadableData` that can be read from a server. Requires a reference to a RemoteDocument.
///
/// - note: There is only a generic version of RemoteData. To get a non-generic version, use `ReadableData` or `Data`.
///
/// Any `RemoteData` that also conforms to `WriteableData` will have access to the `remoteSave()` function.
///
/// - important: These requests can be rejected by the server based on permissions.
///
/// - Required to be `Equatable` so signals can skip duplicates. Mainly used inside `ListenerDataContainer`.
public protocol RemoteData: ReadableData, Equatable {
    
    /// The defined RemoteDocument generic type used in the referenceDoc and init methods.
    associatedtype RemoteDoc: GettableRemoteDataDocument
    
    /// The `remoteDocument` that defines where the data will exist on the server.
    var remoteDocument: RemoteDoc { get }
    
    /// Initializer used to create data from server information.
    /// - Parameters:
    ///   - remoteDocument: The `remoteDocument` where this data exists.
    ///   - dictionary: The data dictionary found at the `remoteDocument` at the server.
    init(remoteDocument: RemoteDoc, dictionary: [String: Any]) throws
}





// MARK: - SAVING
extension RemoteData where
    Self: WriteableData
{
    /// Saves the dictionary to remote.
    ///
    /// - note: May want to add option to override dictionary or create and save fullDictionary which would include location path variables.
    public func remoteSave() -> Promises.Promise<Void> {
        return remoteDocument.save(dictionary: self.dictionary)
    }
}






