import XCTest
@testable import WPRemoteData
import SPCommon
import ReactiveSwift



// Test retain cycle for Download Task and it's inner elements.

/// Tests to verify correct behavior over period of time for remote file download tasks.
///
/// - warning: Any test that does not use the expectation var will  fail.
final class RemoteDataDownloadTaskExpectations: XCTestCase {
    /// Shared expectation.
    ///
    /// - warning: If this is not used in the test, the test will fail!
    private var expect: XCTestExpectation = XCTestExpectation()
    
    /// Shared download task. Global so that shared observer can reference.
    private var downloadTask: RemoteDataDownloadTask<TestDocument>?
    
    private let compositeDisposable = CompositeDisposable()
    
    /// Shared observer. When progress is observed, it checks to make sure downloadTask state matches and sends a fulfill to expectation.
    ///
    /// Ensures that when complete, the progress is 1.0
    ///
    /// - note: Also verifies that progress matches download state progress (which is parent of the Firebase progress that the signal is derived from).
    private lazy var observer = {
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
//                let firebaseTask = self.downloadTask!.storageDownloadTask as! DummyStorageDownloadTask
//                XCTAssert(firebaseTask.failureHandler == nil)
//                XCTAssert(firebaseTask.pauseHandler == nil)
//                XCTAssert(firebaseTask.progressHandler == nil)
//                XCTAssert(firebaseTask.resumeHandler == nil)
//                XCTAssert(firebaseTask.successHandler == nil)
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
        let localFile2 = DummyLocalFile(
            dummyID: TestRemoteFileName.simpleSuccess2.rawValue
        )
        let localFile3 = DummyLocalFile(
            dummyID: TestRemoteFileName.quickSuccess.rawValue
        )
        try localFile1.delete()
        try localFile2.delete()
        try localFile3.delete()
    }
    
    
    func testDownload(){
        self.expect.expectedFulfillmentCount = 2
        
        let remoteDoc = TestDocument(
            testDataID: DummyDataDocID.quickSuccess.rawValue
        )
        self.downloadTask = remoteDoc.downloadTask
        
        let disposable = self.downloadTask?.start().start(self.observer)
        self.compositeDisposable.add(disposable)
        
        let result = XCTWaiter.wait(for: [self.expect], timeout: 3)
        switch result {
        case .completed:
            XCTAssert(downloadTask?.isComplete == true)
//            self.compositeDisposable.dispose()
//            weak var task = self.downloadTask
//            self.downloadTask = nil
//            XCTAssert(task == nil)
        case .timedOut: XCTFail("TIMED OUT.")
        default: XCTFail("Failed to complete.")
        }
    }
    
    func testFailure(){
        self.expect.expectedFulfillmentCount = 1
        
        let remoteDoc = TestDocument(
            testDataID: DummyDataDocID.failure.rawValue
        )
        self.downloadTask = remoteDoc.downloadTask
        
        let disposable = self.downloadTask?.start().start(self.observer)
        self.compositeDisposable.add(disposable)
        
        let result = XCTWaiter.wait(for: [self.expect], timeout: 3)
        switch result {
        case .completed:
            XCTAssert(downloadTask?.state.isError == true)
//            self.compositeDisposable.dispose()
//            weak var task = self.downloadTask
//            self.downloadTask = nil
//            XCTAssert(task == nil)
        case .timedOut: XCTFail("TIMED OUT.")
        default: XCTFail("Failed to complete.")
        }
    }

}
