//
//  UserSessionContainer.swift
//  PlaybackBrain
//
//  Created by William Piotrowski on 12/7/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//
/*
import ReactiveSwift

public class ListenableDataContainer<T: ListenableRemoteData> {
    private static var savingType: SavingType { return .server }
    private let (ListenableDataSignalOutput, listenableDataSignalInput): (
        Signal<ListenableDataReturn<T>, Never>,
        Signal<ListenableDataReturn<T>, Never>.Observer
    )
    private let listenableDataProperty: Property<ListenableDataReturn<T>>
    
    public init(initialData: T){
        let listenableDataSignal = Signal<ListenableDataReturn<T>, Never>.pipe()
        let listenableDataProperty = Property(
            initial: (initialData, nil),
            then: listenableDataSignal.output
        )
        self.listenableDataSignalInput = listenableDataSignal.input
        self.ListenableDataSignalOutput = listenableDataSignal.output
        self.listenableDataProperty = listenableDataProperty
        self.addListener(initialValue: initialData)
    }
}

// MARK: PUBLIC VARS
extension ListenableDataContainer {
    public var listenableData: T {
        get {
            return self.listenableDataProperty.value.data
        }
        set(newValue) {
            self.setSessionData(
                newData: newValue,
                fromDatabaseListener: false
            )
        }
    }
    public var signal: Signal<ListenableDataReturn<T>, Never> {
        return self.listenableDataProperty.signal
    }
}



    
// MARK: SET AND SAVE NEW DATA
extension ListenableDataContainer {
    private func setSessionData(
        newData: T,
        fromDatabaseListener: Bool? = nil
    ){
        let fromDatabaseListener = fromDatabaseListener ?? false
        let previousValue = listenableData
        
        // Do not send or save value if it is the same as existing.
        guard
            newData != previousValue
            else {
                //print("Warning: Did not set type: \(T.self), because it matches existing value.")
                return
        }
        
        self.listenableDataSignalInput.send(
            value: (newData, previousValue)
        )
        
        // Don't save if data is from the server.
        guard !fromDatabaseListener
            else { return }
        saveToRemote(userSessionData: newData)
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

// MARK: ADD LISTENER
extension ListenableDataContainer {
    private func addListener(initialValue: T){
        initialValue.remoteAddListener()
        .observer.observe(
            Signal<T, Error>.Observer(
                value: { userSessionData in
                    self.setSessionData(
                        newData: userSessionData,
                        fromDatabaseListener: true
                    )
                },
                failed: {error in
                    print("USER SESSION NOT DEFINED FROM LISTENER: \(error)")
                }//,
                //completed: {},
                //interrupted: {}
            )
        )
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
*/
