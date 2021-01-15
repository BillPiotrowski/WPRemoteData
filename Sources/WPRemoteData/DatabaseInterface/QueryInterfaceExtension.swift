//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/14/21.
//

import Foundation
import Promises
import ReactiveSwift



// MARK: -
// MARK: GETALL -> PROMISE
extension QueryInterface {
    /// Converts native database response of a Snapshot Block `(DocumentSnapshotInterface?, Error?)` to a promise retiuning `DocumentSnapshotInterface`.
    func getAll() -> Promise<QuerySnapshotInterface> {
        return Promise { fulfill, reject  in
            self.getDocumentsInterface(){ snapshot, queryError in
                do {
                    guard let snapshot = snapshot
                    else {
                        throw DatabaseInterfaceError.missingDocuments
                    }
                    fulfill(snapshot)
                } catch {
                    reject(queryError ?? error)
                }
            }
        }
    }
}






// MARK: -
// MARK: LISTENER
extension QueryInterface {
    
    /// Adds listener to Firestore location.
    /// - Returns: A `Disposable` in the form of `ScorepioListenerDisposable` that conforms to `ListenerRegistrationInterface` (a typealias of Firebase `ListenerRegistration`). This will release the listener on the Firestore database.
    /// A `Signal` containing an optional `QuerySnapshotInterface` and `Error`. `Signal` itself will never send an `Error` value so the signal will not terminate.
    ///
    /// - note: If the signal is interrupted, it wil automatically release Firestore Listener.
    func addListener(
    ) -> (
        ListenerRegistrationInterface,
        Signal<(QuerySnapshotInterface?, Error?), Never>
    ) {
        let pipe = Signal<(
            QuerySnapshotInterface?, Error?
        ), Never>.pipe()
        let disposable = self.addSnapshotListenerInterface { response, error  in
            pipe.input.send(value: (response, error))
        }
        
        // Not called when disposed or when signal is no longer retained by creator.
        pipe.output.observeInterrupted {
            disposable.remove()
        }
        
//        let customDisposal = ScorepioListenerDisposable(){
//            disposable.remove()
//            pipe.input.sendCompleted()
//        }
        
        return (disposable, pipe.output)
    }
    
}


