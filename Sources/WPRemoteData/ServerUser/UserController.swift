//
//  UserController.swift
//  Scorepio
//
//  Created by William Piotrowski on 6/30/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
//import FirebaseUI
import ReactiveSwift
import SPCommon
import PromiseKit

// REMOVE SINGLETON
public typealias ServerAuth = Auth
public typealias ServerEmailAuth = EmailAuthProvider
public class UserController: NSObject {
    //private var authUI: FUIAuth?
    
    public let userSignal: Signal<ServerUser?, Error>
    private let userInput: Signal<ServerUser?, Error>.Observer

    
    public override init(){
        let signal = Signal<ServerUser?, Error>.pipe()
        
        
        //self.authUI = FUIAuth.defaultAuthUI()
        
        self.userInput = signal.input
        self.userSignal = signal.output
        super.init()
        
//        let providers: [FUIAuthProvider] = [
//        ]
        //authUI?.providers = providers
        //authUI?.delegate = self
        
        Auth.auth().addStateDidChangeListener(
            self.userSateChangeHandler
        )
        
    }
    func userSateChangeHandler(_ firebaseAuth: Auth, firebaseUser: User?){
        guard let firebaseUser = firebaseUser
            else {
                // LOGGED OUT IS DIFFERENT THAN ERROR
                userInput.send(value: nil)
                return
        }
        userInput.send(value: ServerUser(user: firebaseUser))
    }
}


extension UserController {
    /*
    public func createLoginVC() -> UINavigationController {
        guard let authUI = authUI else {
           fatalError("Firebase AUTH UI does not exist.")
        }

        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.url = URL(string: "https://example.appspot.com")
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.setAndroidPackageName("com.firebase.example", installIfNotAvailable: false, minimumVersion: "12")

        let provider = FUIEmailAuth(
            authAuthUI: FUIAuth.defaultAuthUI()!,
            signInMethod: EmailLinkAuthSignInMethod,
            forceSameDevice: false,
            allowNewEmailAccounts: true,
            actionCodeSetting: actionCodeSettings
        )

        authUI.providers = [provider]

        let vc = authUI.authViewController()
        return vc
    }
 */
}

extension UserController /*: FUIAuthDelegate*/ {
    /*
    public func authUI(
        _ authUI: FUIAuth,
        didSignInWith user: User?,
        error: Error?
    ) {
        switch user {
        case let user?:
            let serverUser = ServerUser(user: user)
            userInput.send(value: serverUser)
        case nil:
            guard let error = error
                else {
                    // LOGGED OUT IS DIFFERENT THAN ERROR
                    userInput.send(value: nil)
                    return
            }
            userInput.send(error: error)
        }
    }
 */
    public func logout(){
        try? Auth.auth().signOut()
        //try! FUIAuth.defaultAuthUI()!.signOut()
    }
}


extension UserController {
    
    /// Initiates a password reset for the given email address. There are other options that can be explored here as well.
    public static func resetPassword(
        with emailAddress: String
    ) -> Promise<Void> {
        return Promise { seal in
            ServerAuth.auth().sendPasswordReset(
                withEmail: emailAddress
            ){ error in
                guard let error = error
                else {
                    seal.fulfill(())
                    return
                }
                seal.reject(error)
            }
        }
    }
    
    public static func createUser(
        from emailAddress: String,
        password: String
    ) -> Promise<Void> {
        return Promise { seal in
            ServerAuth.auth().createUser(
                withEmail: emailAddress,
                password: password
            ){ (authDataResult, error) in
                guard authDataResult != nil else {
                    let error = error ?? NSError(
                        domain: "Unknown error signing in.",
                        code: 1
                    )
                    seal.reject(error)
                    return
                }
                seal.fulfill(())
            }
        }
    }
    
    public static func login(
        with email: String,
        password: String
    ) -> Promise<Void> {
        return Promise { seal in
            ServerAuth.auth().signIn(
                withEmail: email,
                password: password,
                completion: { (result,error)  in
                    guard result != nil
                    else {
                        let error = error ?? NSError(
                            domain: "No response from login server, but no error provided.",
                            code: 24,
                            userInfo: nil
                        )
                        seal.reject(error)
                        return
                    }
                    seal.fulfill(())
            })
        }
    }
    
    
    public static func reauthenticate(
        password: String
    ) -> Promise<ReauthUser>{
        guard let user = ServerAuth.auth().currentUser
            else {
                return Promise(error: ReauthError.notValidUser)
        }
        // REMOVE SINGLETON
        let credential = ServerEmailAuth.credential(
            withEmail: (user.email)!,
            password: password
        )
        return Promise { seal in
            user.reauthenticate(with: credential){authDataResult, error in
                guard let authDataResult = authDataResult
                    else {
                        seal.reject(error ?? ReauthError.noErrorReturned)
                        return
                }
                let reauthUser = ReauthUser(
                    authDataResult: authDataResult
                )
                seal.fulfill(reauthUser)
            }
        }
    }
    
    private enum ReauthError: ScorepioError {
        case notValidUser
        case noErrorReturned
        
        var message: String {
            switch self {
            case .noErrorReturned:
                return "AuthDataResult not returned from server and no error provided."
            case .notValidUser:
                return "User does not exist. Could not begin authentication."
            }
        }
    }
    public static func changePassword(
        reauthUser: ReauthUser,
        newPassword: String
    ) -> Promise<Void> {
        return Promise { seal in
            reauthUser.authDataResult.user.updatePassword(
                to: newPassword
            ){ error in
                guard let error = error
                    else {
                        seal.fulfill(())
                        return
                }
                seal.reject(error)
            }
        }
    }
    public static func update(
        reauthUser: ReauthUser,
        emailAddress: String
    ) -> Promise<Void> {
        return Promise { seal in
            reauthUser.authDataResult.user.updateEmail(
                to: emailAddress
            ) { error in
                guard let error = error
                    else {
                        seal.fulfill(())
                        return
                }
                seal.reject(error)
            }
        }
    }
}

public struct ReauthUser {
    internal let authDataResult: AuthDataResult
}

 
