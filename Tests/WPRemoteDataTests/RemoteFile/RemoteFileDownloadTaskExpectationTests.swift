import XCTest
@testable import WPRemoteData
import SPCommon
import ReactiveSwift



// Test retain cycle for Download Task and it's inner elements.

/// Tests to verify correct behavior over period of time for remote file download tasks.
///
/// - warning: Any test that does not use the expectation var will  fail.
final class RemoteFileDownloadTaskExpectationTests: XCTestCase {
    /// Shared expectation.
    ///
    /// - warning: If this is not used in the test, the test will fail!
    private var expect: XCTestExpectation = XCTestExpectation()
    
    /// Shared download task. Global so that shared observer can reference.
    private var downloadTask: NewDownloadTask?
    
    private let compositeDisposable = CompositeDisposable()
    
    /// Shared observer. When progress is observed, it checks to make sure downloadTask state matches and sends a fulfill to expectation.
    ///
    /// Ensures that when complete, the progress is 1.0
    ///
    /// - note: Also verifies that progress matches download state progress (which is parent of the Firebase progress that the signal is derived from).
    private lazy var observer = {
        Signal<Double, Error>.Observer(
            value: { progress in
                print("PROGRESS: \(progress)")
                XCTAssert(progress == self.downloadTask?.progress.fractionCompleted)
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
                print("COMPLETE")
                XCTAssert(self.downloadTask?.state == .complete)
                XCTAssert(self.downloadTask?.percentComplete == 1.0)
                self.expect.fulfill()
            }, interrupted: {
                print("Interrupted")
                XCTAssert(self.downloadTask?.state == .paused)
                let firebaseTask = self.downloadTask!.storageDownloadTask as! DummyStorageDownloadTask
                XCTAssert(firebaseTask.failureHandler == nil)
                XCTAssert(firebaseTask.pauseHandler == nil)
                XCTAssert(firebaseTask.progressHandler == nil)
                XCTAssert(firebaseTask.resumeHandler == nil)
                XCTAssert(firebaseTask.successHandler == nil)
//                XCTAssert(self.downloadTask?.storageDownloadTask)
                self.expect.fulfill()
            }
        )
    }()
    
    
    // MARK: - SETUP
    override func setUpWithError() throws {
        ServerAppStarter.configure(ServerAppStarter.Config(forTesting: true))
        self.expect = expectation(description: "Test")
    }
    
    // MARK: - TEAR DOWN
    override func tearDownWithError() throws {
        let localFile1 = DummyLocalFile(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        try localFile1.delete()
    }
    
    // MARK: - ERROR
    func testError() throws {
        self.expect.expectedFulfillmentCount = 3
        
        let remoteFile = DummyRemoteFile(
            dummyID: TestRemoteFileName.error.rawValue
        )
        self.downloadTask = remoteFile.downloadTask2
        
        downloadTask?.start().start(self.observer)
        
        let result = XCTWaiter.wait(for: [self.expect], timeout: 3.0)
        switch result {
        case .completed:
            XCTAssert(downloadTask?.state.isError ?? false)
            self.compositeDisposable.dispose()
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        default: XCTFail("Failed to complete.")
        }
    }
    
    // MARK: - SIMPLE SUCCESS
    func testSimpleSuccess() throws {
        self.expect.expectedFulfillmentCount = 5
        
        let remoteFile = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        self.downloadTask = remoteFile.downloadTask2
        
        let disposabe1 = downloadTask?.start().start(self.observer)
        self.compositeDisposable.add(disposabe1)
        
        let result = XCTWaiter.wait(for: [self.expect], timeout: 6.5)
        switch result {
        case .completed:
            XCTAssert(downloadTask?.state == .complete)
            self.compositeDisposable.dispose()
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        default: XCTFail("Failed to complete.")
        }
    }
    
    // MARK: - CANCEL
    // Should Download task signal of signals complete after error? interrupt?
    func testCancel() throws {
        self.expect.expectedFulfillmentCount = 4
        
        let remoteFile = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        self.downloadTask = remoteFile.downloadTask2
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            self.downloadTask?.cancel()
        }
        
        downloadTask?.start().start(self.observer)
        
        
        let result = XCTWaiter.wait(for: [self.expect], timeout: 4)
        switch result {
        case .completed:
            XCTAssert(downloadTask?.state.isError ?? false)
            self.compositeDisposable.dispose()
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        default: XCTFail("Failed to complete.")
        }
    }
    
    
    // MARK: - PAUSE AND RESUME
    /// Begins the download and after two progress updates, it pauses. Then resumes after 3 seconds.
    func testPauseAndResume() throws {
        // 2 progress
        // 1 pause
        // 3 progress
        // complete
        self.expect.expectedFulfillmentCount = 7
        
        let remoteFile = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        self.downloadTask = remoteFile.downloadTask2
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            self.downloadTask?.pause()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.downloadTask?.start().start(self.observer)
        }
        
        downloadTask?.start().start(self.observer)
        
        
        let result = XCTWaiter.wait(for: [self.expect], timeout: 10)
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
    
    
    
    // MARK: - TEST SECOND START AFTER COMPLETION
    /// Expected to immediately send two events: a value (1.0) and a completion event after attempting to start a completed download.
    func testStartAfterComplete() throws {
        // 5 for the initial complete and 2 for the restart complete
        self.expect.expectedFulfillmentCount = 7
        
        let remoteFile = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        self.downloadTask = remoteFile.downloadTask2
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.downloadTask?.start().start(self.observer)
        }
        
        downloadTask?.start().start(self.observer)
        
        
        let result = XCTWaiter.wait(for: [self.expect], timeout: 6.5)
        switch result {
        case .completed:
            XCTAssert(self.downloadTask?.isComplete ?? false)
            self.compositeDisposable.dispose()
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        default: XCTFail("Failed to complete.")
        }
    }
    
    
    // MARK: - TEST ALREADY LOCAL
    /// Expected to immediately send two events: a value (1.0) and a completion event after attempting to start a download where the file already exists on the device.
    func testAlreadyLocal() throws {
        self.expect.expectedFulfillmentCount = 2
        
        // Using a dummy data file as easiest way to save to disk.
        let dummyData = DummyLocalData(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        try dummyData.saveToDisk()
        
        let remoteFile = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        
        XCTAssert(remoteFile.isLocal)
        
        self.downloadTask = remoteFile.downloadTask2
        
        downloadTask?.start().start(self.observer)
        
        let result = XCTWaiter.wait(for: [self.expect], timeout: 2.5)
        switch result {
        case .completed:
            XCTAssert(downloadTask?.isComplete ?? false)
            self.compositeDisposable.dispose()
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        default: XCTFail("Failed to complete.")
        }
    }
    
    
    // MARK: - HARD REFRESH
    /// Expected to create a normal download request with 5 status updates even though the file is local because hard refresh is selected.
    func testHardRefresh() throws {
        self.expect.expectedFulfillmentCount = 5
        
        // Using a dummy data file as easiest way to save to disk.
        let dummyData = DummyLocalData(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        try dummyData.saveToDisk()
        
        let remoteFile = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        
        XCTAssert(remoteFile.isLocal)
        
        self.downloadTask = remoteFile.createDownloadTask(
            hardRefresh: true
        )
        
        downloadTask?.start().start(self.observer)
        
        let result = XCTWaiter.wait(for: [self.expect], timeout: 3.5)
        switch result {
        case .completed:
            XCTAssert(downloadTask?.isComplete ?? false)
            self.compositeDisposable.dispose()
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        default: XCTFail("Failed to complete.")
        }
    }
    
    
}
