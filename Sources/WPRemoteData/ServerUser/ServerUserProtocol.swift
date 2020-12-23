//
//  ServerUserProtocol.swift
//  Scorepio
//
//  Created by William Piotrowski on 6/30/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import Firebase
import FirebaseAuth

public struct ServerUser {
    public let user: User
}
extension ServerUser {
    public var uid: String { return user.uid }
    public func getIDToken(completion: @escaping (String?, Error?) -> Void){
        user.getIDToken(completion: completion)
    }
}


