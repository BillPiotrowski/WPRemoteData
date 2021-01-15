//
//  ReadableRemoteDataSimpleGetAll.swift
//  Scorepio
//
//  Created by William Piotrowski on 3/6/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import Foundation
import Promises

public protocol ReadableRemoteDataKnownFolder: ReadableRemoteData {
    static var remoteDataTypeFolder: RemoteDataLocation { get }
}

//extension ReadableRemoteDataKnownFolder {
//    public static func getAll(
//        filters: [WhereFilter]? = nil
//    ) -> Promise<[Self]> {
//        return Self.remoteGetAll(
//            serverLocation: Self.remoteDataTypeFolder,
//            filters: filters
//        )
//    }
//}
