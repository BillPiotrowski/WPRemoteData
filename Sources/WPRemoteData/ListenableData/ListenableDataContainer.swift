//
//  UserSessionContainer.swift
//  PlaybackBrain
//
//  Created by William Piotrowski on 12/7/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import ReactiveSwift

public class ListenableDataContainer<T: ListenableRemoteData> {
    private static var savingType: SavingType { return .server }
    private let savingType: SavingType
    private let userPipe: Signal<T, Never>.Observer
    private let mergedProperty: Property<T>
    // Different from ReactiveSwift Disposable.
    weak private var disposable: ListenerDisposable?
    
    public init(
        initialData: T,
        forTesting: Bool? = nil
    ){
        let forTesting = forTesting ?? false
        let savingType = forTesting ? SavingType.local : SavingType.server
        
        // CREATE MERGED PIPE TO SERVER AND USER SIGNALS
        let mergedPipe = Signal<Signal<ListenableDataReturnItem<T>, Never>, Never>.pipe()
        let flattenedSignal: Signal<ListenableDataReturnItem<T>, Never> = mergedPipe.output.flatten(.merge)
        
        
        let userPipe = Signal<T, Never>.pipe()
        
        if !forTesting {
            let rawServerResponse = initialData.remoteAddListenerNoError()
            let formattedServerResponse = rawServerResponse.observer.signal.compactMap { response -> ListenableDataReturnItem<T>? in
                switch response {
                case .error: return nil
                case .success(let temp):
                    return ListenableDataReturnItem(
                        newData: temp,
                        fromDatabaseListener: true
                    )
                }
            }
            mergedPipe.input.send(value: formattedServerResponse)
            self.disposable = rawServerResponse.disposable
        }
        
        // FORMAT USER SIGNAL WITH: fromDatabaseListener = false
        // AND ADD TO MERGED
        let formattedUserSignal: Signal<ListenableDataReturnItem<T>, Never> = userPipe.output.map { data in
            return ListenableDataReturnItem(newData: data, fromDatabaseListener: false)
        }
        mergedPipe.input.send(value: formattedUserSignal)
            
        // COMPLETE MERGED PIPE
        mergedPipe.input.sendCompleted()

        
        // MAINTAINS PREVIOUS ELEMENT
        let filteredSignal = flattenedSignal.skipRepeats().map{ vars -> T in
            return vars.newData
        }
        
        // CREATES PROPERTY
        let listenableDataProperty = Property(
            initial: initialData,
            then: filteredSignal
        )
        
        // SETS PROPERTIES
        self.userPipe = userPipe.input
        self.mergedProperty = listenableDataProperty
        self.savingType = savingType
        
        // SETS SAVE OBSERVATION
        formattedUserSignal.observeValues{ data in
            self.saveToRemote(userSessionData: data.newData)
        }
    }
}

// MARK: PUBLIC VARS
extension ListenableDataContainer {
    public var listenableData: T {
        get {
            return self.mergedProperty.value
        }
        set(newValue) {
            userPipe.send(value: newValue)
        }
    }
    public var signal: Signal<T, Never> {
        return self.mergedProperty.signal
    }
}



// MARK: SAVE METHOD
extension ListenableDataContainer {
    private func saveToRemote(userSessionData: T){
        switch self.savingType {
        case .server:
            userSessionData.remoteSave()
            .done{ _ in
                //print("SAVED SESSION 2")
            }
            .catch{ error in
                print("ERROR SAVING SESSION!!")
            }
        case .local: break
        // BUILD OUT LOCAL IMPLEMENTATION!!
        /*
            do{
                try userSessionData.archive()
            } catch {
                print("ERROR SAVING TO LOCAL: \(error).")
            }
            */
        }
    }
}

// MARK: DEFINITIONS:
private enum SavingType {
    case server
    case local
}

public typealias ListenableDataReturn<T: ListenableRemoteData>  = (
    data: T,
    previousData: T?
)
public struct ListenableDataReturnItem<T: ListenableRemoteData>: Equatable {
    let newData: T
    let fromDatabaseListener: Bool
}
