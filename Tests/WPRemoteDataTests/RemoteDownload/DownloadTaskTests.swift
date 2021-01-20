import XCTest
@testable import WPRemoteData
import SPCommon
import ReactiveSwift

class DownloadTaskTests: XCTestCase {
    
    /// Shared expectation.
    ///
    /// - warning: If this is not used in the test, the test will fail!
    var expect: XCTestExpectation = XCTestExpectation()
    var progressSigTerminationExp: XCTestExpectation = XCTestExpectation()
    
    /// Shared download task. Global so that shared observer can reference.
    var downloadTask: NewDownloadTaskProtocol?
    
    let compositeDisposable = CompositeDisposable()
    
    /// Shared observer. When progress is observed, it checks to make sure downloadTask state matches and sends a fulfill to expectation.
    ///
    /// Ensures that when complete, the progress is 1.0
    ///
    /// - note: Also verifies that progress matches download state progress (which is parent of the Firebase progress that the signal is derived from).
    lazy var observer = {
        Signal<Double, Error>.Observer(
            value: { progress in
                print("PROGRESS: \(progress) vs. \(self.downloadTask!.progress.fractionCompleted)")
                
                // If both are local, this test can happen too quickly and be inaccurate when relying on the subtask isLocal guard instead of the group islocal guard.
//                XCTAssert(progress == self.downloadTask?.progress.fractionCompleted)
                
                XCTAssert(
                    self.downloadTask?.state == .loading ||
                    // Will send a single progress if attempting to restart when already complete.
                    (self.downloadTask?.isComplete ?? false)
                )
                self.expect.fulfill()
            }, failed: { error in
                print("ERROR: \(error)")
                XCTAssert(self.downloadTask?.state.isError ?? false)
                self.expect.fulfill()
            }, completed: {
                print("COMPLETE: \(self.downloadTask!.progress.fractionCompleted)")
                XCTAssert(self.downloadTask?.state == .complete)
                XCTAssert(self.downloadTask?.percentComplete == 1.0)
                self.expect.fulfill()
            }, interrupted: {
                print("Interrupted")
                XCTAssert(self.downloadTask?.state == .paused)
                self.expect.fulfill()
            }
        )
    }()
    
    
    
    // MARK: - ASSERT SUCCESS
    func assertSuccess(
        timeout: Double? = nil
    ){
        let timeout = timeout ?? 7
        
        // ASSERT SIGNAL COMPLETES
        self.progressSigTerminationExp.expectedFulfillmentCount = 1
        self.downloadTask?.progressSignal.observeCompleted {
            self.progressSigTerminationExp.fulfill()
        }
        
        
        let disposable = self.downloadTask?.start().start(self.observer)
        self.compositeDisposable.add(disposable)
        
        let result = XCTWaiter.wait(
            for: [
                self.expect,
                self.progressSigTerminationExp
            ],
            timeout: timeout
        )
        switch result {
        case .completed:
            XCTAssert(downloadTask?.isComplete == true)
            
            
            // STATE LOCKED TEST
            downloadTask?.attemptCancel()
            XCTAssert(self.downloadTask?.isComplete == true)
            downloadTask?.attemptPause()
            XCTAssert(self.downloadTask?.isComplete == true)
            
            
            self.compositeDisposable.dispose()
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        case .timedOut: XCTFail("TIMED OUT.")
        default: XCTFail("Failed to complete.")
        }
        
        
    }
    
    
    // MARK: - ASSERT FAIL
    func assertFail(
        timeout: Double? = nil
    ){
        let timeout = timeout ?? 3
        
        
        // ASSERT SIGNAL COMPLETES
        self.progressSigTerminationExp.expectedFulfillmentCount = 1
        self.downloadTask?.progressSignal.observeFailed { _ in
            self.progressSigTerminationExp.fulfill()
        }
        
        let disposable = self.downloadTask?.start().start(self.observer)
        self.compositeDisposable.add(disposable)
        
        let result = XCTWaiter.wait(
            for: [self.expect, self.progressSigTerminationExp],
            timeout: timeout
        )
        switch result {
        case .completed:
            XCTAssert(downloadTask?.state.isError == true)
            
            // STATE LOCKED TEST
            downloadTask?.attemptPause()
            XCTAssert(self.downloadTask?.state.isError == true)
            
            self.compositeDisposable.dispose()
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        case .timedOut: XCTFail("TIMED OUT.")
        default: XCTFail("Failed to complete.")
        }
    }
    
    
    
    // MARK: - ASSERT CANCEL
    func assertCancel(
        cancelDelay: Double? = nil,
        timeout: Double? = nil
    ){
        let cancelDelay = cancelDelay ?? 0.8
        let timeout = timeout ?? 3
        
        // ASSERT SIGNAL COMPLETES
        self.progressSigTerminationExp.expectedFulfillmentCount = 1
        self.downloadTask?.progressSignal.observeFailed { _ in
            self.progressSigTerminationExp.fulfill()
        }
        
        let disposable = self.downloadTask?.start().start(self.observer)
        self.compositeDisposable.add(disposable)

        
        DispatchQueue.main.asyncAfter(deadline: .now() + cancelDelay) {
            self.downloadTask?.attemptCancel()
        }
        
        let result = XCTWaiter.wait(
            for: [self.expect, self.progressSigTerminationExp],
            timeout: timeout
        )
        switch result {
        case .completed:
            XCTAssert(downloadTask?.state.isError == true)
            self.compositeDisposable.dispose()
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        case .timedOut: XCTFail("TIMED OUT.")
        default: XCTFail("Failed to complete.")
        }
    }
    
    
    
    // MARK: - ASSERT PAUSE AND RESUME
    func assertPauseAndResume(
        pauseDelay: Double? = nil,
        restartDelay: Double? = nil,
        timeout: Double? = nil
    ){
        let pauseDelay = pauseDelay ?? 1.1
        let restartDelay = restartDelay ?? 1.5
        let timeout = timeout ?? 10
        
        
        // ASSERT SIGNAL COMPLETES
        self.progressSigTerminationExp.expectedFulfillmentCount = 1
        self.downloadTask?.progressSignal.observeCompleted {
            self.progressSigTerminationExp.fulfill()
        }
        
        
        self.downloadTask?.progressSignal.observeInterrupted {
            XCTFail("This signal should never interrupt!")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + pauseDelay) {
            self.downloadTask?.attemptPause()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + restartDelay) {
            self.downloadTask?.start().start(self.observer)
        }
        
        downloadTask?.start().start(self.observer)
        
        
        let result = XCTWaiter.wait(
            for: [self.expect, self.progressSigTerminationExp],
            timeout: timeout
        )
        switch result {
        case .completed:
            XCTAssert(downloadTask?.state.isComplete ?? false)
            self.compositeDisposable.dispose()
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        default: XCTFail("Failed to complete.")
        }
    }
    
    // MARK: - ASSERT AFTER SUCCESS
    func assertStartAfterSuccess(
        retryDelay: Double? = nil,
        timeout: Double? = nil
    ){
        let retryDelay = retryDelay ?? 5
        let timeout = timeout ?? 8
        
        
        
        // ASSERT SIGNAL COMPLETES
        self.progressSigTerminationExp.expectedFulfillmentCount = 1
        self.downloadTask?.progressSignal.observeCompleted {
            self.progressSigTerminationExp.fulfill()
        }
        
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
            self.downloadTask?.start().start(self.observer)
        }
        
        downloadTask?.start().start(self.observer)
        
        
        let result = XCTWaiter.wait(
            for: [self.expect, self.progressSigTerminationExp],
            timeout: timeout
        )
        switch result {
        case .completed:
            XCTAssert(self.downloadTask?.isComplete ?? false)
            
            // STATE LOCKED TEST
            downloadTask?.attemptCancel()
            XCTAssert(self.downloadTask?.isComplete == true)
            downloadTask?.attemptPause()
            XCTAssert(self.downloadTask?.isComplete == true)
            
            // RETAIN TEST
            self.compositeDisposable.dispose()
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        default: XCTFail("Failed to complete.")
        }
    }
    
    
    
    // MARK: - RESTART AFTER ERROR!!
    func assertRestartAfterError(
        retryDelay: Double? = nil,
        timeout: Double? = nil
    ){
        let retryDelay = retryDelay ?? 5
        let timeout = timeout ?? 8
        
        
        
        // ASSERT SIGNAL COMPLETES
        self.progressSigTerminationExp.expectedFulfillmentCount = 1
        self.downloadTask?.progressSignal.observeFailed { _ in
            self.progressSigTerminationExp.fulfill()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
            self.downloadTask?.start().start(self.observer)
        }
        
        downloadTask?.start().start(self.observer)
        
        
        let result = XCTWaiter.wait(
            for: [self.expect, self.progressSigTerminationExp],
            timeout: timeout
        )
        switch result {
        case .completed:
            XCTAssert(downloadTask?.state.isError == true)
            
            // STATE LOCKED TEST
            downloadTask?.attemptPause()
            XCTAssert(self.downloadTask?.state.isError == true)
            
            self.compositeDisposable.dispose()
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        case .timedOut: XCTFail("TIMED OUT.")
        default: XCTFail("Failed to complete.")
        }
    }
    
}


