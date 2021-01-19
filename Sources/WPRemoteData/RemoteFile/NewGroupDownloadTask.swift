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
    private let hardRefresh: Bool
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
    private var userInitiatedInput: (Signal<Double, Error>.Observer)?
    
    let downloadOrder: DownloadOrder
    static let downloadOrderDefault = DownloadOrder.sequential
    
    init(
        downloadTasks: [NewDownloadTaskProtocol],
        hardRefresh: Bool,
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
        let flattenedSignal = progressSignalsPipe.output.flatten(.merge).map{ _ -> Double in
            return progress.fractionCompleted
        }
        
        
        for task in downloadTasks {
            progressSignalsPipe.input.send(value: task.progressSignal)
//            task.progressSignal.observe(Signal<Double, Error>.Observer(value: {val in
//                print("INNER VAL: \(val)")
//            }, failed: {error in
//                print("INNER SIG ERROR: \(error)")
//            }, completed: {
//                print("INNER SIG COMPLETE")
//            }, interrupted: {
//                print("INNER SIG INTERRUPTED")
//            }))
            progress.addChild(
                task.progress,
                withPendingUnitCount: 100
            )
        }
        progressSignalsPipe.input.sendCompleted()
        
        let disposable1 = flattenedSignal.observe(
            Signal<Signal<Double, Error>.Value, Error>.Observer(
                value: { val in
                    statePipe.input.send(value: .loading)
                }, failed: { error in
                    statePipe.input.send(value: .failure(error: error))
                }, completed: {
                    statePipe.input.send(value: .complete)
                    statePipe.input.sendCompleted()
                }, interrupted: {
                    // Does not bubble up to outter from inner signals.
                }
            )
        )
        
        self.progressSignalsInput = progressSignalsPipe.input
        self.progress = progress
        self.hardRefresh = hardRefresh
        self.stateProperty = stateProperty
        self.stateInput = statePipe.input
        self.subtasks = downloadTasks
        self.progressSignal = flattenedSignal
        self.downloadOrder = downloadOrder
        
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
        
        self.lifecycleDisposable.add(disposable1)
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
            print("IS COMPLETE!")
            return SignalProducer<Double, Error>.init(
                value: self.percentComplete
            )
        }
        guard hardRefresh || !isLocal
        else {
            print("IS LOCAL!")
            progress.completedUnitCount = progress.totalUnitCount
            self.progressSignalsInput.sendCompleted()
            return SignalProducer<Double, Error>.init(
                value: self.percentComplete
            )
        }
        
        
        // Not sure I can observe both on pipe.
        let signalPipe = Signal<Double, Error>.pipe()
        let disposable = self.progressSignal.observe(signalPipe.input)
        self.userInitiatedInput = signalPipe.input
        
        switch downloadOrder {
        case .parallel:
            self.startParallel()
            return signalPipe.output.producer
        case .sequential:
            return self.startSequential(signal: signalPipe.output)
        }
        
    }
    
    private func startParallel(){
        print("START PARALLEL!")
        for task in subtasks {
            print("ATTEMPT START TASK")
            guard !task.isComplete
            else { return }
            task.start().start(Signal<Double, Error>.Observer(value: {val in
                print("SUBTASK: VAL \(val)")
            }, failed: {error in
                print("SUBTASK: ERROR")
            }, completed: {
                print("SUBTASK: COMPLETED")
            }, interrupted: {
                print("SUBTASK: INTERRUPTED")
                self.handleInterruption()
            }
            ))
            print("START TASK")
        }
    }
    
    private func handleInterruption(){
        self.stateInput.send(value: .paused)
        self.userInitiatedInput?.sendInterrupted()
    }
    
    private func startSequential(
        signal: Signal<Double, Error>
    ) -> SignalProducer<Double, Error> {
        do {
            try self.startNextTask()
        } catch {
            return SignalProducer<Double, Error>.init(
                error: error
            )
        }
        return signal.producer
    }
    
    /// Escaping recursive function that starts the next task and when it completes calls itself to begin the next task.
    private func startNextTask() throws {
        guard let nextTask = nextTask
        else {
            throw NSError(domain: "no next task", code: 2)
        }
        nextTask.start().start(
            Signal<Double, Error>.Observer(
                value: {_ in
                    
                },
                failed: {_ in
                    
                },
                completed: {
                    do {
                        try self.startNextTask()
                    } catch {
                        // CHECK IF COMPLETE AND THROW ERROR IF NOT?
                    }
                },
                interrupted: self.handleInterruption
            )
        )
    }
    
    
    /// Returns the first task that is not complete.
    var nextTask: NewDownloadTaskProtocol? {
        subtasks.first { !$0.isComplete }
    }
    
    var isLocal: Bool {
        for task in subtasks {
            guard task.isLocal
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
