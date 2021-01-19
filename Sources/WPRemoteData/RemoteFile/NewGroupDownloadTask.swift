//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/18/21.
//

import Foundation
import ReactiveSwift

// serial vs parallel
// sequential
class NewGroupDownloadTask {
    public var hardRefresh: Bool
    private let subtasks: [NewDownloadTaskProtocol]
    
    public let stateProperty: Property<NewDownloadTaskState>
    private let stateInput: Signal<NewDownloadTaskState, Never>.Observer
    let progressSignal: Signal<Double, Error>
    private var progressSignalsInput: Signal<Signal<Double, Error>, Error>.Observer
    
    var progress: Progress
    private let lifecycleDisposable = CompositeDisposable()
    
    /// This gives the class access to the signal that is returned on start. Mainly used for pausing.
    ///
    /// Is interrupting on pause still a good idea?
//    private var userInitiatedInput: (Signal<Double, Error>.Observer)?
    
//    private var currentMaster: (Signal<Double, Error>)?
    
    let downloadOrder: DownloadOrder
    static let downloadOrderDefault = DownloadOrder.sequential
    
    var interruptableInput: (Signal<Double, Error>.Observer)?
//    var masterInput: (Signal<Signal<Double, Error>, Error>.Observer)?
    
    init(
        downloadTasks: [NewDownloadTaskProtocol],
        hardRefresh: Bool? = nil,
        downloadOrder: DownloadOrder? = nil
    ){
        let downloadOrder = downloadOrder ?? Self.downloadOrderDefault
        let progress: Progress = Progress()
        progress.fileOperationKind = .downloading
        progress.totalUnitCount = Int64(downloadTasks.count * 100)
        
        let initialState = NewDownloadTaskState.initialized
        
        let statePipe = Signal<NewDownloadTaskState, Never>.pipe()
        let stateProperty = Property(
            initial: initialState,
            then: statePipe.output
        )
        
        let progressSignalsPipe = Signal<Signal<Double, Error>, Error>.pipe()
        let flattenedSignal = progressSignalsPipe.output.flatten(.latest).map{ _ -> Double in
            return progress.fractionCompleted
        }
        
        
        for task in downloadTasks {
//            progressSignalsPipe.input.send(value: task.progressSignal)
            progress.addChild(
                task.progress,
                withPendingUnitCount: 100
            )
            if let hardRefresh = hardRefresh {
                task.hardRefresh = hardRefresh
            }
        }
        let hardRefresh = hardRefresh ?? NewGroupDownloadTask.defaultHardRefresh
//        progressSignalsPipe.input.sendCompleted()
        
        
        self.progressSignalsInput = progressSignalsPipe.input
        self.progress = progress
        self.hardRefresh = hardRefresh
        self.stateProperty = stateProperty
        self.stateInput = statePipe.input
        self.subtasks = downloadTasks
        self.progressSignal = flattenedSignal
        self.downloadOrder = downloadOrder
        
        /*
        let disposable1 = flattenedSignal.observe(
            Signal<Signal<Double, Error>.Value, Error>.Observer(
                value: { val in
                    print("FINAL FINAL VAL: \(val)")
                    statePipe.input.send(value: .loading)
                }, failed: { error in
                    print("FINAL FINAL ERROR: \(error)")
                    statePipe.input.send(value: .failure(error: error))
                }, completed: {
                    print("FINAL FINAL ATTEMPT COMPLETE")
                    guard self.areSubtasksComplete
                    else {
                        self.interruptableInput?.sendInterrupted()
                        statePipe.input.send(value: .paused)
                        return
                    }
                    print("FINAL FINAL COMPLETE")
                    statePipe.input.send(value: .complete)
                    statePipe.input.sendCompleted()
                }, interrupted: {
                    print("SHOULD NEVER SEE THIS INTERRUPTED!")
                    // Does not bubble up to outter from inner signals.
                }
            )
        )
        */
        
        
        // MARK: - INIT COMPLETE
        
        let disposable2 = self.stateProperty.producer.startWithValues {
            switch $0 {
            case .paused:
                // REMOVING ALL OBSERVERS WILL CAUSE HANLDER TO NOT BE CALLED. NOT USING YET, SO NOT A BIG DEAL.
//                self.storageDownloadTask?.removeAllObservers()
                break
                
            case .complete:
                // These are not required, but cleaning up.
//                self.storageDownloadTask?.removeAllObservers()
                self.lifecycleDisposable.dispose()
//                self.storageDownloadTask = nil
                break
                
            case .failure:
                // These are not required, but cleaning up.
//                self.storageDownloadTask?.removeAllObservers()
//                self.storageDownloadTask = nil
                
                // !!! REQUIRED: !!!
                self.lifecycleDisposable.dispose()
                break
                
            case .loading, .initialized: break
            }
        }
        
//        self.lifecycleDisposable.add(disposable1)
        self.lifecycleDisposable.add(disposable2)
    }
}
 
// MARK: - CONFORM: NewDownloadTaskProtocol
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
            self.progressSignalsInput.sendCompleted()
            self.stateInput.send(value: .complete)
            return SignalProducer<Double, Error>.init(
                value: self.percentComplete
            )
        }
        
        
        /// This is the pipe that all signal producers from subtask start() merge to.
        ///
        /// May need to handle this slightly differently at some point in case tasks complete prior to the completion of this pipe.
        /// - May need to use an action to start all subtasks at once on parallel?
        /// - Or expose the interruptable signal of subtask to the pipe can be generated and returned prior to starting.
        let masterPipe = Signal<Signal<Double, Error>, Error>.pipe()
        
        /// Signal creating by flattening (merge) the master pipe output.
        ///
        /// Side injection replacing the inner task's completion with the global Progress item completion.
        ///
        /// - warning: DO NOT SEND TO END USER. MUST BE SENT TO INTERRUPTABLE FIRST. Merge interprets inner signal's interruptions as completion, making pause / interruptions appear to be completions.
        let flattenedMaster = masterPipe.output.flatten(.merge).map{
            _ -> Double in
            self.percentComplete
        }.delay(0.1, on: QueueScheduler.main)
        
        
        
//        let newMasterPipe = Signal<Signal<Double, Error>, Error>.pipe()
//        let newInterruptable = Signal<Double, Error>.pipe()
//
//
//        var taskSignalPairs = [TaskSignalPair]()
//        for task in subtasks {
//            let newPipe = Signal<Double, Error>.pipe()
//            newMasterPipe.input.send(value: newPipe.output)
//            taskSignalPairs.append(
//                TaskSignalPair(task: task, signal: newPipe.input)
//            )
//        }
//
//        newInterruptable.input.send(value: newMasterPipe.output.flatten(.merge).map {_ -> Double in
//            return self.percentComplete
//        })
        
        
        
        
        /// A pipe created to allow the subtask master pipe to be manually interrupted.
        ///
        /// Since flattening (merge) a signal will cause interruptions to be treated as completions, this pipe is created to allow some gymnastics to take place to interrupt.
        ///
        /// Already commited to idea that pause = interruption, so to continue this design, each subtask will create an observer prior to attaching to the master. If that subtask is interrupted, it interrupts this signal first.
        let interruptablePipe = Signal<Double, Error>.pipe()
        
        
        
        
        // Send flattened master to interruptablePipe.
        flattenedMaster.observe(interruptablePipe.input)
        
        let newSig = interruptablePipe.output.on(
            event: {_ in},
            failed: { error in
                self.progressSignalsInput.sendCompleted()
                self.stateInput.send(value: .failure(error: error))
                self.stateInput.sendCompleted()
                self.lifecycleDisposable.dispose()
            },
            completed: {
                guard self.areSubtasksComplete
                else {
                    return
                }
                self.progressSignalsInput.sendCompleted()
                self.stateInput.send(value: .complete)
                self.stateInput.sendCompleted()
            },
            interrupted: {
                self.stateInput.send(value: .paused)
            },
            terminated: {},
            disposed: {},
            value: {_ in
                self.stateInput.send(value: .loading)
            }
        )
        
        
        
        
//
//
//            value: { val in
//                print("FINAL FINAL VAL: \(val)")
//                statePipe.input.send(value: .loading)
//            }, failed: { error in
//                print("FINAL FINAL ERROR: \(error)")
//                statePipe.input.send(value: .failure(error: error))
//            }, completed: {
//                print("FINAL FINAL ATTEMPT COMPLETE")
//                guard self.areSubtasksComplete
//                else {
//                    self.interruptableInput?.sendInterrupted()
//                    statePipe.input.send(value: .paused)
//                    return
//                }
//                print("FINAL FINAL COMPLETE")
//                statePipe.input.send(value: .complete)
//                statePipe.input.sendCompleted()
//            }, interrupted: {
//                print("SHOULD NEVER SEE THIS INTERRUPTED!")
//                // Does not bubble up to outter from inner signals.
//            }
//
//
//
        
        
        
        
        
        // ORDER IS IMPORTANT.
        // MUST OBSERVE BEFORE SENDING TO self.progressSignalsInput TO BE ABLE TO CLOSE SIGNALS INPUT.
        // SO THAT IF COMPLETED, IT CAN COMPLETE self.progressSignalsInput
//        interruptablePipe.output.producer.startWithCompleted {
//        }
        self.progressSignalsInput.send(value: newSig)
    
        self.interruptableInput = interruptablePipe.input
        
        switch downloadOrder {
        case .parallel:
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.startParallel(masterPipe: masterPipe.input)
//            }
            return newSig.producer
        case .sequential:
            
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.startSequential(masterPipe: masterPipe.input)
//            }
            return newSig.producer
        }
        
    }
}

// MARK: - PARALLEL
extension NewGroupDownloadTask {
    private func startParallel(
        masterPipe: Signal<Signal<Double, Error>, Error>.Observer
    ) {
        for task in subtasks {
            /// An intermediate signal is created so that the task signal producer can be observed.
            /// - important: Need to observe the subtasks interruption prior to sending to master pipe so that any interruption is captured and handled prior to sending to master.
            let newSignal = Signal<Double, Error>.pipe()
            newSignal.output.producer.startWithInterrupted {
                self.handleInterruption()
            }
            masterPipe.send(value: newSignal.output)
            
            // START SUBTASK
            task.start().start(newSignal.input)
        }
        masterPipe.sendCompleted()
    }
}
 
// MARK: - SEQUENTIAL
extension NewGroupDownloadTask {
    private func startSequential(
        masterPipe: Signal<Signal<Double, Error>, Error>.Observer
    ){
        do {
            print("TRY NEXT TASK")
            try self.startNextTask(masterPipe: masterPipe)
        } catch {
            print("NO NEXT TASK")
//            return SignalProducer<Double, Error>.init(
//                error: error
//            )
        }
//        return signal.producer
    }
    
    /// Escaping recursive function that starts the next task and when it completes calls itself to begin the next task.
    private func startNextTask(
        masterPipe: Signal<Signal<Double, Error>, Error>.Observer
    ) throws {
        guard let nextTask = nextTask
        else {
            throw NSError(domain: "no next task", code: 2)
        }
        
        /// An intermediate signal is created so that the task signal producer can be observed.
        /// - important: Need to observe the subtasks interruption prior to sending to master pipe so that any interruption is captured and handled prior to sending to master.
        let newSignal = Signal<Double, Error>.pipe()
//        newSignal.output.producer.startWithInterrupted {
//            self.handleInterruption()
//        }
//        newSignal.output.producer.startWithCompleted {
//        }
        masterPipe.send(value: newSignal.output)
        
        // Closes master pipe if this is the final task to complete
        if self.incompleteSubtasks < 2 {
            masterPipe.sendCompleted()
        }
        
//        masterPipe.send(value:
//        )
        let temp = nextTask.start().on(
//            starting: {},
//            started: {},
//            event: {_ in},
//            failed: { error in},
            completed: {
                do {
                    try self.startNextTask(masterPipe: masterPipe)
                } catch {
                    // CHECK IF COMPLETE AND THROW ERROR IF NOT?
                }
            },
            interrupted: {
                self.handleInterruption()
            },
            terminated: {},
            disposed: {},
            value: {_ in}
        ).start(newSignal.input)
        
    }
    
    private func handleInterruption(){
        self.stateInput.send(value: .paused)
        self.interruptableInput?.sendInterrupted()
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
        // Have to manually set state to paused because an inner signal's interruption is not bubbled up to the master signal in a flattened operator.
        // Setting state first so testing can verify.
        // This is consistent with how the other observers are set. Since they are set in init, they are called prior to the external signal observer.
    }
    
    
    func attemptCancel() {
        for task in subtasks {
            task.attemptCancel()
        }
        //
    }
    
    var state: NewDownloadTaskState {
        self.stateProperty.value
    }
    
    
    enum DownloadOrder {
        case parallel, sequential
    }
}




struct DownloadSession {
    
    let tasks: [TaskSignalPair]
}


struct TaskSignalPair {
    let task: NewDownloadTaskProtocol
    let signal: Signal<Double, Error>.Observer
}
