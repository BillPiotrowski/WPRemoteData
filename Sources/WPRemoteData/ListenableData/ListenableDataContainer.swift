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
    private let userPipe: Signal<T, Never>.Observer
    private let mergedProperty: Property<ListenableDataReturn<T>>
    weak private var disposable: ListenerDisposable?
    
    public init(initialData: T){
        
        
        let ServerPipe = Signal<ListenableDataReturnItem<T>, Never>.pipe()
        let userPipe = Signal<T, Never>.pipe()
        let rawServerResponse = initialData.remoteAddListenerNoError()
        
        // ADD fromDatabaseListener: false TO USER SIGNAL
        let formattedUserSignal: Signal<ListenableDataReturnItem<T>, Never> = userPipe.output.map { data in
            return (newData: data, fromDatabaseListener: false)
        }
            
        // MANUALLY FILTERING AND CONFIGURING SERVER DATA
        rawServerResponse.observer.observeValues{
            value in
            switch value {
            case .error(let error):
                print("NON FATAL ERROR: \(error)")
                return
            case .success(let response):
                ServerPipe.input.send(
                    value: (
                        newData: response,
                        fromDatabaseListener: true
                    )
                )
            }
        }
        
        // MERGE AND FLATTEN SERVER AND USER SIGNALS
        let mergedPipe = Signal<Signal<ListenableDataReturnItem<T>, Never>, Never>.pipe()
        let flattenedSignal = mergedPipe.output.flatten(.merge)
        mergedPipe.input.send(value: ServerPipe.output)
        mergedPipe.input.send(value: formattedUserSignal)
        mergedPipe.input.sendCompleted()

        // MAINTAINS PREVIOUS ELEMENT
        let previousSignal = flattenedSignal.combinePrevious(
            (newData: initialData, fromDatabaseListener: false)
        )
        
        // FILTER REPEAT EVENTS
        let filteredSignal = previousSignal.filter { args in
            guard args.0.newData != args.1.newData
                else { return false }
            return true
        }
        
        // FORMATS AS ListenableDataReturn
        let responseSignal:Signal<ListenableDataReturn<T>, Never> = filteredSignal.map {
            args in
            return (
                data: args.1.newData,
                previousData: args.0.newData
            )
            
        }
        
        // CREATES PROPERTY
        let listenableDataProperty = Property(
            initial: (initialData, nil),
            then: responseSignal
        )
        
        // SETS PROPERTIES
        self.userPipe = userPipe.input
        self.mergedProperty = listenableDataProperty
        self.disposable = rawServerResponse.disposable
        
        // SETS SAVE OBSERVATION
        filteredSignal.observeValues{ args in
            guard !args.1.fromDatabaseListener else {
                return
            }
            self.saveToRemote(userSessionData: args.1.newData)
        }
    }
}

// MARK: PUBLIC VARS
extension ListenableDataContainer {
    public var listenableData: T {
        get {
            return self.mergedProperty.value.data
        }
        set(newValue) {
            userPipe.send(value: newValue)
        }
    }
    public var signal: Signal<ListenableDataReturn<T>, Never> {
        return self.mergedProperty.signal
    }
}



// MARK: SAVE METHOD
extension ListenableDataContainer {
    private func saveToRemote(userSessionData: T){
        switch ListenableDataContainer.savingType {
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
public typealias ListenableDataReturnItem<T: ListenableRemoteData>  = (
    newData: T,
    fromDatabaseListener: Bool
)
