//
//  FirestoreProtocols.swift
//  RPG Music
//
//  Created by William Piotrowski on 4/14/19.
//  Copyright © 2019 William Piotrowski. All rights reserved.
//

import Foundation

// SEPARATE INTO REMOTE WRITEABLE / REMOTE READABLE

public protocol RemoteData {
    //associatedtype myType
    var remoteDataReference: RemoteDataReference { get }
}



















