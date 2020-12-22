//
//  RemoteReadableData.swift
//  Scorepio
//
//  Created by William Piotrowski on 3/6/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import Foundation
import PromiseKit
import SPCommon3
import Firebase

public protocol WriteableRemoteData: WriteableData, RemoteData {
}

// WRITEABLE
extension WriteableRemoteData {
    /*
    @available(*, deprecated, message: "Use remoteSave()->Promise<Void>")
    public func save(completionHandler: @escaping (Error?) -> Void) {
        self.remoteSave()
        .done{ temp in
            completionHandler(nil)
        }
        .catch{ error in
            completionHandler(error)
        }
    }
 */
    public func remoteSave() -> Promise<Void> {
        return remoteDataReference.save(dictionary: self.dictionary)
    }
}

