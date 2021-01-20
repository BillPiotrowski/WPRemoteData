//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/18/21.
//

import Foundation
import ReactiveSwift

class NewGroupDownloadTask {
    public var hardRefresh: Bool
    private let subtasks: [NewDownloadTaskProtocol]
    
    public let stateProperty: Property<NewDownloadTaskState>
    private let stateInput: Signal<NewDownloadTaskState, Never>.Observer
    let progressSignal: Signal<Double, Error>
//    private var progressSignalsInput: Signal<Signal<Double, Error>, Error>.Observer
    
    var progress: Progress
    private let lifecycleDisposable: CompositeDisposable
    
    let downloadOrder: DownloadOrder
    static let downloadOrderDefault = DownloadOrder.sequential
    
    var interruptableInput: (Signal<Double, Error>.Observer)?
    
    let newProgressSignal: Signal<Double, Error>
    
    let sigProdPipe: (output: Signal<Double, Error>, input: Signal<Double, Error>.Observer)
    
    
//    private lazy var subtaskObserver: Signal<Double, Error>.Observer = {[unowned self]
//        Signal<Double, Error>.Observer(
////            value: {val in },
//            failed: { error in
//                self.stateInput.send(value: .failure(error: error))
//            },
//            completed: {
//                guard case .sequential = self.downloadOrder
//                else { return }
//                try? self.startNextTask()
//            },
//            interrupted: {
//                self.stateInput.send(value: .paused)
//            }
//        )
//    }()
//
    init(
        downloadTasks: [NewDownloadTaskProtocol],
        hardRefresh: Bool? = nil,
        downloadOrder: DownloadOrder? = nil
    ){
        let lifecycleDisposable = CompositeDisposable()
        
        let downloadOrder = downloadOrder ?? Self.downloadOrderDefault
        let progress: Progress = Progress()
        progress.fileOperationKind = .downloading
        progress.totalUnitCount = Int64(downloadTasks.count * 100)
        
        let initialState = NewDownloadTaskState.initialized
        
        
        let subtaskStatePipe = Signal<Signal<Double, Error>, Error>.pipe()
        let subtaskStateSignal = subtaskStatePipe.output.flatten(.merge)
        
        for task in downloadTasks {
            subtaskStatePipe.input.send(value: task.progressSignal)
        }
        subtaskStatePipe.input.sendCompleted()
        
        let sigProdPipe = Signal<Double, Error>.pipe()
        
        
//        subtaskStateSignal.observeValues { val in
//            print("SUBTASK STATE: \(val)")
//        }
//        
        
        let statePipe = Signal<NewDownloadTaskState, Never>.pipe()
        let stateProperty = Property(
            initial: initialState,
            then: statePipe.output
        )
        
//        let progressSignalsPipe = Signal<Signal<Double, Error>, Error>.pipe()
//        let flattenedSignal = progressSignalsPipe.output.flatten(.latest).map{ _ -> Double in
//            return progress.fractionCompleted
//        }
        let disposable4 = subtaskStateSignal.producer.startWithCompleted {
            print("MASTER COMPLETE@@#@#$#@")
            statePipe.input.send(value: .complete)
            statePipe.input.sendCompleted()
            lifecycleDisposable.dispose()
        }
        let disposable5 = subtaskStateSignal.producer.startWithFailed {
            statePipe.input.send(value: .failure(error: $0))
            statePipe.input.sendCompleted()
            lifecycleDisposable.dispose()
        }
        
        
        let newProgressSignal = subtaskStateSignal.map { _ -> Double in
            progress.fractionCompleted
        }
        
        
        
        
        
        
        for task in downloadTasks {
            progress.addChild(
                task.progress,
                withPendingUnitCount: 100
            )
            if let hardRefresh = hardRefresh {
                task.hardRefresh = hardRefresh
            }
        }
        let hardRefresh = hardRefresh ?? NewGroupDownloadTask.defaultHardRefresh
        
        
//        self.progressSignalsInput = newProgressSignal
        self.progress = progress
        self.hardRefresh = hardRefresh
        self.stateProperty = stateProperty
        self.stateInput = statePipe.input
        self.subtasks = downloadTasks
        self.progressSignal = newProgressSignal
        self.downloadOrder = downloadOrder
        self.newProgressSignal = newProgressSignal
        self.sigProdPipe = sigProdPipe
        self.lifecycleDisposable = lifecycleDisposable
        
        
//        self.lifecycleDisposable.add(disposable4)
    }
}
 
// MARK: - START
extension NewGroupDownloadTask: NewDownloadTaskProtocol {
    
    /// Starts or resumes the download task and returns a signal of progress.
    ///
    /// Needs to return a signal producer that
    /// - sends all progress updates,
    /// - interrupts on pause,
    /// - terminates on error, and
    /// - completes when all children complete
    ///
    /// Not sure it is the right decision to interrupt, but making that design choice.
    /// Benefit is that it makes starting / pausing / resuming clean. Ensures that there is only one signal producer out at a time.
    /// Down side is that pausing might not perfectly fit the definition of interruption, although it's close.
    /// Also is confusing because the signal will interrupt for other reasons besides pause. But I'm comfortable with those being treated as a pause as well.
    func start() -> SignalProducer<Double, Error> {
        
        guard !self.isComplete
        else {
            return SignalProducer<Double, Error>.init(
                value: self.percentComplete
            )
        }
        guard hardRefresh || !isLocal
        else {
            progress.completedUnitCount = progress.totalUnitCount
//            self.progressSignalsInput.sendCompleted()
            self.stateInput.send(value: .complete)
            return SignalProducer<Double, Error>.init(
                value: self.percentComplete
            )
        }
        
        
        /// This is the pipe that all signal producers from subtask start() merge to.
        ///
        /// - warning: RACE CONDITION: There is a race condition between starting the signals and returning the signal producer. Straight-forward code requires subtasks to be started prior to returning the signal producer.
        ///
        /// Current solution is to add a .1 second delay which does seem to fix issues.
        ///
        /// Also, the worst case situation is when all files are local, the subtasks immediately return completed which is not recieved by the user without the delay (and possibly even with delay). This is mitigated by have the local check at the top of this function and not relying on the individual subtasks.
        ///
        /// Removing the delay and the above isLocal guard WILL cause problems when all files are local and possibly other problems.
        ///
        /// - May need to use an action to start all subtasks at once on parallel?
//        let masterPipe = Signal<Signal<Double, Error>, Error>.pipe()
//
//        /// Signal creating by flattening (merge) the master pipe output.
//        ///
//        /// Side injection replacing the inner task's completion with the global Progress item completion.
//        ///
//        /// - warning: DO NOT SEND TO END USER. MUST BE SENT TO INTERRUPTABLE FIRST. Merge interprets inner signal's interruptions as completion, making pause / interruptions appear to be completions.
//        ///
//        /// Should delay send to a different qos?
//        let flattenedMaster = masterPipe.output.flatten(.merge).map{
//            _ -> Double in
//            self.percentComplete
//        }.delay(0.1, on: QueueScheduler.main)
//
//
//
//        /// A pipe created to allow the subtask master pipe to be manually interrupted.
//        ///
//        /// Since flattening (merge) a signal will cause interruptions to be treated as completions, this pipe is created to allow immediate observers using on(:) directly on subtasks to interrupt prior to bubbling up as a completion..
//        ///
//        /// Already commited to idea that pause = interruption, so to continue this design, each subtask will create an observer prior to attaching to the master. If that subtask is interrupted, it interrupts this signal first.
//        let interruptablePipe = Signal<Double, Error>.pipe()
//
//
//        // Send flattened master to interruptablePipe.
//        flattenedMaster.observe(interruptablePipe.input)
//
//        let newSig = interruptablePipe.output.on(
//            failed: { error in
//                self.progressSignalsInput.sendCompleted()
//                self.stateInput.send(value: .failure(error: error))
//                self.stateInput.sendCompleted()
//
//                // !!! -- REQUIRED -- !!!
//                self.lifecycleDisposable.dispose()
//            },
//            completed: {
//                guard self.areSubtasksComplete
//                else {
//                    return
//                }
//                self.progressSignalsInput.sendCompleted()
//                self.stateInput.send(value: .complete)
//                self.stateInput.sendCompleted()
//            },
//            interrupted: {
//                self.stateInput.send(value: .paused)
//            },
//            value: {_ in
//                self.stateInput.send(value: .loading)
//            }
//        )
//
//
//
//        // ORDER IS IMPORTANT.
//        // MUST OBSERVE BEFORE SENDING TO self.progressSignalsInput TO BE ABLE TO CLOSE SIGNALS INPUT.
//        // SO THAT IF COMPLETED, IT CAN COMPLETE self.progressSignalsInput
//        self.progressSignalsInput.send(value: newSig)
//
//        self.interruptableInput = interruptablePipe.input
//
        self.stateInput.send(value: .loading)
        
        switch downloadOrder {
        case .parallel:
            self.startParallel()
//            return newSig.producer
        case .sequential:
            try? self.startNextTask()
//            return newSig.producer
        }
        
        return SignalProducer.init { (input, lifetime) in
            input.send(value: self.percentComplete)
            let dis2 = self.newProgressSignal.observe(input)
            // send prog
            // send prog sig
            // then check for sresults.
            
            let state = self.state
            switch state {
            case .complete:
//                input.send(value: 1.0)
                input.sendCompleted()
            case .failure(let error):
                input.send(error: error)
            case .initialized:
                break
            case .loading: break
//                input.send(value: self.percentComplete)
            case .paused:
//                input.send(value: self.percentComplete)
                input.sendInterrupted()
            }
            
            let dis3 = self.sigProdPipe.output.observe(input)
            let disposable = self.stateProperty.producer.startWithValues {
                switch $0 {
                case .complete: break
//                    input.sendCompleted()
                case .failure(let error): break
//                    input.send(error: error)
                case .loading, .initialized: break
                case .paused: input.sendInterrupted()
                }
            }
//            input.send()
            lifetime.observeEnded {
                dis2?.dispose()
                disposable.dispose()
                dis3?.dispose()
//                self.lifecycleDisposable.dispose()
            }
        }
        
    }
}

// MARK: - PARALLEL
extension NewGroupDownloadTask {
    private func startParallel(
//        masterPipe: Signal<Signal<Double, Error>, Error>.Observer
    ) {
        for task in subtasks {
            /// An intermediate signal is created so that the task signal producer can be observed.
            /// - important: Need to observe the subtasks interruption prior to sending to master pipe so that any interruption is captured and handled prior to sending to master.
//            let newSignal = Signal<Double, Error>.pipe()
//            masterPipe.send(value: newSignal.output)
            let _ = task.start()//.start(Signal<Double, Error>.Observer(
                //            value: {val in },
//                            failed: { error in
//                                self.stateInput.send(value: .failure(error: error))
//                            },
//                            completed: {
//                                guard case .sequential = self.downloadOrder
//                                else { return }
//                                try? self.startNextTask()
//                            },
//                            interrupted: {
//                                self.stateInput.send(value: .paused)
//                            }
//                        ))
//            self.lifecycleDisposable.add(disposable)
//            self.lifecycleDisposable.add(disposable)
            // START SUBTASK
//            let disposable = task.start().on(
//                interrupted: {
//                    self.handleInterruption()
//                }
//            ).start(newSignal.input)
//
//            self.lifecycleDisposable.add(disposable)
        }
//        masterPipe.sendCompleted()
    }
}
 
// MARK: - SEQUENTIAL
extension NewGroupDownloadTask {
//    private func startSequential(
//        masterPipe: Signal<Signal<Double, Error>, Error>.Observer
//    ){
//        do {
//            try self.startNextTask(masterPipe: masterPipe)
//        } catch {
//        }
//    }
    
    /// Escaping recursive function that starts the next task and when it completes calls itself to begin the next task.
    private func startNextTask(
//        masterPipe: Signal<Signal<Double, Error>, Error>.Observer
    ) throws {
        guard let nextTask = nextTask
        else {
            throw NSError(domain: "no next task", code: 2)
        }
        
        /// An intermediate signal is created so that the task signal producer can be observed.
        /// - important: Need to observe the subtasks interruption prior to sending to master pipe so that any interruption is captured and handled prior to sending to master.
//        let newSignal = Signal<Double, Error>.pipe()
//
//        masterPipe.send(value: newSignal.output)
//
//        // Closes master pipe if this is the final task to complete
//        if self.incompleteSubtasks < 2 {
//            masterPipe.sendCompleted()
//        }
//
//        let disposable = nextTask.start().on(
//            completed: {
//                do {
//                    try self.startNextTask(masterPipe: masterPipe)
//                } catch {
//                    // CHECK IF COMPLETE AND THROW ERROR IF NOT?
//                }
//            },
//            interrupted: {
//                self.handleInterruption()
//            }
//        ).start(newSignal.input)
//
//        self.lifecycleDisposable.add(disposable)
        let disposable = nextTask.start().start(Signal<Double, Error>.Observer(
            //            value: {val in },
//                        failed: { error in
//                            self.stateInput.send(value: .failure(error: error))
//                        },
                        completed: {
//                            guard case .sequential = self.downloadOrder
//                            else { return }
                            try? self.startNextTask()
                        }//,
//                        interrupted: {
//                            self.stateInput.send(value: .paused)
//                        }
                    ))
        self.lifecycleDisposable.add(disposable)
//        let disposable = nextTask.start().startWithCompleted {
//            try? self.startNextTask(masterPipe: masterPipe)
//        }
    }
    
    private func handleInterruption(){
//        self.stateInput.send(value: .paused)
//        self.interruptableInput?.sendInterrupted()
    }
    
}

// MARK: - COMPUTED VARS
extension NewGroupDownloadTask {
    
    /// Returns the first task that is not complete.
    private var nextTask: NewDownloadTaskProtocol? {
        subtasks.first { !$0.isComplete }
    }
    
    private var incompleteSubtasks: Int {
        subtasks.compactMap{ response -> NewDownloadTaskProtocol? in
            guard !response.isComplete else { return nil }
            return response
        }.count
    }
    
    var isLocal: Bool {
        for task in subtasks {
            guard task.isLocal
            else { return false }
        }
        return true
    }
    
    private var areSubtasksComplete: Bool {
        for task in subtasks {
            guard task.isComplete
            else { return false }
        }
        return true
    }
    
    
    func attemptPause() {
        for task in subtasks {
            task.attemptPause()
        }
        self.stateInput.send(value: .paused)
        // Have to manually set state to paused because an inner signal's interruption is not bubbled up to the master signal in a flattened operator.
        // Setting state first so testing can verify.
        // This is consistent with how the other observers are set. Since they are set in init, they are called prior to the external signal observer.
    }
    
    
    func attemptCancel() {
        for task in subtasks {
            task.attemptCancel()
        }
        self.stateInput.send(
            value: .failure(error: NSError(domain: "Cancelled", code: 2))
        )
        //
    }
    
    var state: NewDownloadTaskState {
        self.stateProperty.value
    }
    
    
    enum DownloadOrder {
        case parallel, sequential
    }
}
