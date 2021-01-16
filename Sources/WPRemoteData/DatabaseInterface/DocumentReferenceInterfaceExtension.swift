//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/14/21.
//

import Foundation
import Promises
import ReactiveSwift

// MARK: GET
extension DocumentReferenceInterface {
    func get() -> Promise<DocumentSnapshotInterface>{
        return Promise { fulfill, reject in
            self.getDocumentInterface { snapshot, queryError in
                do {
                    guard let snapshot = snapshot
                    else {
                        throw DatabaseInterfaceError.missingDocument(
                            path: self.path
                        )
                    }
                    fulfill(snapshot)
                } catch {
                    reject(queryError ?? error)
                }
            }
        }
    }
}

extension DocumentReferenceInterface {
    /// - seealso: See `QueryInterface` -> `AddListener` for more information about testing and Disposables.
    func addListener() ->
        (ListenerRegistrationInterface,
        Signal<(DocumentSnapshotInterface?, Error?), Never>
    ) {
        let pipe = Signal<(
            DocumentSnapshotInterface?, Error?
        ), Never>.pipe()
        let disposable = self.addSnapshotListenerInterface { response, error  in
            pipe.input.send(value: (response, error))
        }
        
        // Not called when disposed or when signal is no longer retained by creator.
        pipe.output.observeInterrupted {
            disposable.remove()
        }
        
        return (disposable, pipe.output)
    }
}