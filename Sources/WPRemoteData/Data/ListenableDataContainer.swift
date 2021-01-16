//
//  UserSessionContainer.swift
//  PlaybackBrain
//
//  Created by William Piotrowski on 12/7/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import ReactiveSwift
import SPCommon

/*
public class ListenableDataContainer<T: RemoteDataReference,
                                     D: RemoteDataGeneric> {
    private static var savingType: SavingType { return .server }
    private let savingType: SavingType
    private let userPipe: Signal<D, Never>.Observer
    private let mergedProperty: Property<T>
    // Different from ReactiveSwift Disposable.
    weak private var disposable: ListenerDisposable?
    
    fileprivate init(
        savingType: SavingType,
        userPipe: Signal<D, Never>.Observer,
        mergedProperty: Property<T>
    ){
        self.savingType = savingType
        self.userPipe = userPipe
        self.mergedProperty = mergedProperty
    }
}

extension ListenableDataContainer where
    T: RemoteDataReferenceGeneric,
//    Self: RemoteDataReferenceGeneric,
//    Self.Data.Reference == Self
    T == D.Reference,
    T.Data == D
{
    public convenience init(
        initialData: D,
        forTesting: Bool? = nil
    ){

*/







public class ListenableDataContainer<
    Data: RemoteData,
    RemoteDoc: GettableRemoteDataDocument
> {
    private static var savingType: SavingType { return .server }
    private let savingType: SavingType
    private let userPipe: Signal<Data, Never>.Observer
    private let mergedProperty: Property<Data>
    // Different from ReactiveSwift Disposable.
    weak private var disposable: ListenerRegistrationInterface?
    
    
    fileprivate init(
        savingType: SavingType,
        userPipe: Signal<Data, Never>.Observer,
        mergedProperty: Property<Data>,
        disposable: ListenerRegistrationInterface?
    ){
        self.savingType = savingType
        self.userPipe = userPipe
        self.mergedProperty = mergedProperty
        self.disposable = disposable
    }
    
    deinit {
        print("DID DEINIT LISTENABLEDATA CONTAINER!!!")
    }
}

extension ListenableDataContainer where
//    T: RemoteDataReferenceGeneric,
//    Self: RemoteDataReferenceGeneric,
    //    Self.Data.Reference == Self
//    T == D.Reference,
//    T.Data == D
    Data.RemoteDoc == RemoteDoc,
    RemoteDoc: GettableRemoteDataDocument,
    RemoteDoc.Data == Data,
//    Data: ListenableRemoteData,
    Data: WriteableData
    
{
    public convenience init(
        initialData: Data,
        forTesting: Bool? = nil
    ){
        let forTesting = forTesting ?? false
        let savingType = forTesting ? SavingType.local : SavingType.server
        
        // CREATE MERGED PIPE TO SERVER AND USER SIGNALS
        let mergedPipe = Signal<Signal<ListenableDataReturnItem<Data>, Never>, Never>.pipe()
        let flattenedSignal: Signal<ListenableDataReturnItem<Data>, Never> = mergedPipe.output.flatten(.merge)
        
        
        let userPipe = Signal<Data, Never>.pipe()
        
        
        // NOT NECESSARY WITH NEW INJECTABLE TESTING
        let disposable: ListenerRegistrationInterface?
        if !forTesting {
            let rawServerResponse = initialData.remoteDocument.addListener()
            
            
            
//            initialData.remoteAddListenerNoError()
            let formattedServerResponse = rawServerResponse.1.signal.compactMap {
                response -> ListenableDataReturnItem<Data>? in
                
                guard let snapshot = response.0 else { return nil }
                return ListenableDataReturnItem(
                    newData: snapshot.data,
                    fromDatabaseListener: true
                )
                
            }
                
                
//                rawServerResponse.observer.signal.compactMap { response -> ListenableDataReturnItem<Data>? in
//                switch response {
//                case .error: return nil
//                case .success(let temp):
//                    return ListenableDataReturnItem(
//                        newData: temp,
//                        fromDatabaseListener: true
//                    )
//                }
            //            }
            mergedPipe.input.send(value: formattedServerResponse)
            disposable = rawServerResponse.0
        } else {
            disposable = nil
        }
        
        // FORMAT USER SIGNAL WITH: fromDatabaseListener = false
        // AND ADD TO MERGED
        let formattedUserSignal: Signal<ListenableDataReturnItem<Data>, Never> = userPipe.output.map { data in
            return ListenableDataReturnItem(newData: data, fromDatabaseListener: false)
        }
        mergedPipe.input.send(value: formattedUserSignal)
            
        // COMPLETE MERGED PIPE
        mergedPipe.input.sendCompleted()

        
        // MAINTAINS PREVIOUS ELEMENT
        let filteredSignal = flattenedSignal.skipRepeats().map{ vars -> Data in
            return vars.newData
        }
        
        // CREATES PROPERTY
        let listenableDataProperty = Property(
            initial: initialData,
            then: filteredSignal
        )
        
        // SETS PROPERTIES
        self.init(
            savingType: savingType,
            userPipe: userPipe.input,
            mergedProperty: listenableDataProperty,
            disposable: disposable
        )
//        self.userPipe = userPipe.input
//        self.mergedProperty = listenableDataProperty
//        self.savingType = savingType
        
        // SETS SAVE OBSERVATION
        formattedUserSignal.observeValues{ data in
            self.saveToRemote(userSessionData: data.newData)
        }
    }
    
    // MARK: SAVE METHOD
//    extension ListenableDataContainer {
    private func saveToRemote(userSessionData: Data){
        switch self.savingType {
        case .server:
            userSessionData.remoteSave()
            .then{ _ in
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


// MARK: PUBLIC VARS
extension ListenableDataContainer {
    public var listenableData: Data {
        get {
            return self.mergedProperty.value
        }
        set(newValue) {
            userPipe.send(value: newValue)
        }
    }
//    public var signal: Signal<T, Never> {
//        return self.mergedProperty.signal
//    }
    public var signalProducer: SignalProducer<Data, Never>{
        return self.mergedProperty.producer
    }
    public func stopListening(){
        self.disposable?.remove()
        self.userPipe.sendCompleted()
    }
}


// MARK: DEFINITIONS:
private enum SavingType {
    case server
    case local
}

/*
public struct ListenableDataReturnItem<
    Data: RemoteDataGeneric,
    RemoteDoc: RemoteDataReferenceGeneric
> {
    let doc: ScorepioQueryResponse<RemoteDoc, Data>
//    let newData: Data
    let fromDatabaseListener: Bool
}
extension ListenableDataReturnItem: Equatable where
    Data: Equatable,
    RemoteDoc: Equatable
{

}
*/

public struct ListenableDataReturnItem<T: RemoteData>: Equatable {
    let newData: T
    let fromDatabaseListener: Bool
}
