//
//  ServerApp.swift
//  RemoteDataDynamic
//
//  Created by William Piotrowski on 12/18/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import Firebase
import FirebaseStorage

/// Public class for configuring Firestore. Will instantiate the Firestore singleton to be used throughout application.
///
/// Can configure to inject a Dummy database for testing.
///
/// - authors: Designed based on solution found here:
///
///  https://stackoverflow.com/questions/28429544/singleton-and-init-with-parameter
public class ServerAppStarter {
    
    /// Instantiation of Firestore database or injected class for testing.
    let db: DatabaseInterface
    let storage: StorageInterface
    let testDataDictionaries: [String: [String: Any]]
    
    /// The singleton version of this class.
    ///
    /// - warning: Will default to production version if static configure() method is not called prior to referencing this singleton.
    static let shared = ServerAppStarter()
    
    /// Must be set prior to init using configure() method. If not, default is used.
    private static var config: Config?

    
// MARK: - INIT
    private init() {
        let config = ServerAppStarter.config ?? ServerAppStarter.defaultConfiguration
        switch config.forTesting {
        case true:
            self.db = DummyDatabase.shared
            self.storage = DummyStorage()
            self.testDataDictionaries = config.testDataDictionaries ?? [:]
        case false:
            self.db = Firestore.firestore()
            self.storage = Storage.storage()
            self.testDataDictionaries = [:]
        }
    }
    
    
}

// MARK: - PUBLIC CONFIG METHOD
extension ServerAppStarter {
    /// Set up the properties to be used by server database.
    public class func configure(_ config: Config? = nil){
        let config = config ?? ServerAppStarter.defaultConfiguration
        switch config.forTesting {
        case true: break
        case false:
            FirebaseApp.configure()
        }
        ServerAppStarter.config = config
    }
}


// MARK: - DEFAULT CONFIG
extension ServerAppStarter {
    /// Sets the default configuration to production server.
    private static var defaultConfiguration: Config {
        Config(
            forTesting: false,
            testDataDictionaries: nil
        )
    }
}

// MARK: - CONFIG STRUCT DEFINITION
extension ServerAppStarter {
    
    /// Configurable properties of external database.
    ///
    /// - note: Used in the configure() method of this class.
    ///
    /// Can add more information relevant to production settings if necessary:
    ///
    /// https://firebase.google.com/docs/reference/swift/firebasecore/api/reference/Classes/FirebaseApp
    public struct Config {
        var forTesting: Bool
        let testDataDictionaries: [String: [String: Any]]?
    }
}
