import XCTest
@testable import WPRemoteData
import SPCommon
import ReactiveSwift



// Test retain cycle for Download Task and it's inner elements.

/// Tests to verify correct behavior over period of time for remote file download tasks.
///
/// - warning: Any test that does not use the expectation var will  fail.
final class GroupDownloadExpectationTests: XCTestCase {
    /// Shared expectation.
    ///
    /// - warning: If this is not used in the test, the test will fail!
    private var expect: XCTestExpectation = XCTestExpectation()
    
    /// Shared download task. Global so that shared observer can reference.
    private var downloadTask: NewGroupDownloadTask?
    
    private let compositeDisposable = CompositeDisposable()
    
    /// Shared observer. When progress is observed, it checks to make sure downloadTask state matches and sends a fulfill to expectation.
    ///
    /// Ensures that when complete, the progress is 1.0
    ///
    /// - note: Also verifies that progress matches download state progress (which is parent of the Firebase progress that the signal is derived from).
    private lazy var observer = {
        Signal<Double, Error>.Observer(
            value: { progress in
                print("PROGRESS: \(self.downloadTask!.state) \(progress) vs. \(self.downloadTask!.progress.fractionCompleted)")
                
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
    
    
    // MARK: - TEST 2 SIMPLE SUCCESS SEQUENTIAL
    func testTwoSimpleSuccessSeq(){
        // 4 progress
        // 4 progress
        // complete
        self.expect.expectedFulfillmentCount = 8
        
        let remoteFile1 = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        let remoteFile2 = DummyRemoteFile(
            dummyID: TestRemoteFileName.quickSuccess.rawValue
        )
        var subtask1: NewDownloadTaskProtocol? = remoteFile1.downloadTask2
        var subtask2: NewDownloadTaskProtocol? = remoteFile2.downloadTask2
        
        self.downloadTask = NewGroupDownloadTask(
            downloadTasks: [subtask1!, subtask2!],
            hardRefresh: false
        )
        
        downloadTask?.start().start(self.observer)
        
        let result = XCTWaiter.wait(for: [self.expect], timeout: 7)
        switch result {
        case .completed:
            XCTAssert(downloadTask?.isComplete == true)
            self.compositeDisposable.dispose()
            subtask1 = nil
            subtask2 = nil
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        case .timedOut: XCTFail("TIMED OUT.")
        default: XCTFail("Failed to complete.")
        }
    }
    
    
    
    
    
    // MARK: - TEST 3 SIMPLE SUCCESS SEQUENTIAL
    func test2File1DataSequenctial(){
        // 4 progress
        // 4 progress
        // complete
        self.expect.expectedFulfillmentCount = 9
        
        let remoteFile1 = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        let remoteFile2 = DummyRemoteFile(
            dummyID: TestRemoteFileName.quickSuccess.rawValue
        )
        let remoteDoc = TestDocument(
            testDataID: DummyDataDocID.quickSuccess.rawValue
        )
        
        var subtask1: NewDownloadTaskProtocol? = remoteFile1.downloadTask2
        var subtask2: NewDownloadTaskProtocol? = remoteFile2.downloadTask2
        var subtask3: NewDownloadTaskProtocol? = remoteDoc.downloadTaskProtocol
        
        self.downloadTask = NewGroupDownloadTask(
            downloadTasks: [subtask1!, subtask2!, subtask3!],
            hardRefresh: false
        )
        
        downloadTask?.start().start(self.observer)
        
        let result = XCTWaiter.wait(for: [self.expect], timeout: 7)
        switch result {
        case .completed:
            XCTAssert(downloadTask?.isComplete == true)
            self.compositeDisposable.dispose()
            subtask1 = nil
            subtask2 = nil
            subtask3 = nil
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        case .timedOut: XCTFail("TIMED OUT.")
        default: XCTFail("Failed to complete.")
        }
    }
    
    // MARK: - TEST 2 SIMPLE SUCCESS PARALLEL
    func testTwoSimpleSuccessParallel(){
        // 4 progress
        // 4 progress
        // complete
        self.expect.expectedFulfillmentCount = 8
        
        let remoteFile1 = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        let remoteFile2 = DummyRemoteFile(
            dummyID: TestRemoteFileName.quickSuccess.rawValue
        )
        var subtask1: NewDownloadTaskProtocol? = remoteFile1.downloadTask2
        var subtask2: NewDownloadTaskProtocol? = remoteFile2.downloadTask2
        
        self.downloadTask = NewGroupDownloadTask(
            downloadTasks: [subtask1!, subtask2!],
            hardRefresh: false,
            downloadOrder: .parallel
        )
        
        downloadTask?.start().start(self.observer)
        
        let result = XCTWaiter.wait(for: [self.expect], timeout: 8)
        switch result {
        case .completed:
            XCTAssert(downloadTask?.isComplete == true)
            self.compositeDisposable.dispose()
            subtask1 = nil
            subtask2 = nil
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        case .timedOut: XCTFail("TIMED OUT.")
        default: XCTFail("Failed to complete.")
        }
    }
    
    
    // MARK: - TEST ERROR
    func testErrorSeq(){
        // 4 progress
        // 2 progress
        // error
        self.expect.expectedFulfillmentCount = 8
        
        let remoteFile1 = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        let remoteFile2 = DummyRemoteFile(
            dummyID: TestRemoteFileName.error.rawValue
        )
        var subtask1: NewDownloadTaskProtocol? = remoteFile1.downloadTask2
        var subtask2: NewDownloadTaskProtocol? = remoteFile2.downloadTask2
        
        self.downloadTask = NewGroupDownloadTask(
            downloadTasks: [subtask1!, subtask2!],
            hardRefresh: false
        )
        
        downloadTask?.start().start(self.observer)
        
        let result = XCTWaiter.wait(for: [self.expect], timeout: 7)
        switch result {
        case .completed:
            XCTAssert(downloadTask?.state.isError == true)
            self.compositeDisposable.dispose()
            subtask1 = nil
            subtask2 = nil
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        case .timedOut: XCTFail("TIMED OUT.")
        default: XCTFail("Failed to complete.")
        }
    }
    
    
    // MARK: - TEST ERROR PARALLEL
    func testErrorPar(){
        // 3 progress
        // 2 progress
        // error
        self.expect.expectedFulfillmentCount = 7
        
        let remoteFile1 = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        let remoteFile2 = DummyRemoteFile(
            dummyID: TestRemoteFileName.error.rawValue
        )
        var subtask1: NewDownloadTaskProtocol? = remoteFile1.downloadTask2
        var subtask2: NewDownloadTaskProtocol? = remoteFile2.downloadTask2
        
        self.downloadTask = NewGroupDownloadTask(
            downloadTasks: [subtask1!, subtask2!],
            hardRefresh: false,
            downloadOrder: .parallel
        )
        
        downloadTask?.start().start(self.observer)
        
        let result = XCTWaiter.wait(for: [self.expect], timeout: 7)
        switch result {
        case .completed:
            XCTAssert(downloadTask?.state.isError == true)
            self.compositeDisposable.dispose()
            subtask1 = nil
            subtask2 = nil
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        case .timedOut: XCTFail("TIMED OUT.")
        default: XCTFail("Failed to complete.")
        }
    }
    
    // MARK: - TEST CANCEL
    func testCancelSeq(){
        // 4 progress
        // 1 progress
        // error
        self.expect.expectedFulfillmentCount = 7
        
        let remoteFile1 = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        let remoteFile2 = DummyRemoteFile(
            dummyID: TestRemoteFileName.error.rawValue
        )
        var subtask1: NewDownloadTaskProtocol? = remoteFile1.downloadTask2
        var subtask2: NewDownloadTaskProtocol? = remoteFile2.downloadTask2
        
        self.downloadTask = NewGroupDownloadTask(
            downloadTasks: [subtask1!, subtask2!],
            hardRefresh: false
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) {
            self.downloadTask?.attemptCancel()
        }
        
        downloadTask?.start().start(self.observer)
        
        let result = XCTWaiter.wait(for: [self.expect], timeout: 7)
        switch result {
        case .completed:
            XCTAssert(downloadTask?.state.isError == true)
            self.compositeDisposable.dispose()
            subtask1 = nil
            subtask2 = nil
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        case .timedOut: XCTFail("TIMED OUT.")
        default: XCTFail("Failed to complete.")
        }
    }
    
    
    // MARK: - TEST CANCEL PARALLEL
    func testCancelParallel(){
        // 2 progress
        // 2 progress
        // error
        self.expect.expectedFulfillmentCount = 6
        
        let remoteFile1 = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        let remoteFile2 = DummyRemoteFile(
            dummyID: TestRemoteFileName.error.rawValue
        )
        var subtask1: NewDownloadTaskProtocol? = remoteFile1.downloadTask2
        var subtask2: NewDownloadTaskProtocol? = remoteFile2.downloadTask2
        
        self.downloadTask = NewGroupDownloadTask(
            downloadTasks: [subtask1!, subtask2!],
            hardRefresh: false,
            downloadOrder: .parallel
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            self.downloadTask?.attemptCancel()
        }
        
        downloadTask?.start().start(self.observer)
        
        let result = XCTWaiter.wait(for: [self.expect], timeout: 7)
        switch result {
        case .completed:
            XCTAssert(downloadTask?.state.isError == true)
            self.compositeDisposable.dispose()
            subtask1 = nil
            subtask2 = nil
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        case .timedOut: XCTFail("TIMED OUT.")
        default: XCTFail("Failed to complete.")
        }
    }
    
    // MARK: - TEST PAUSE / RESTART
    func testPauseAndRestartSeq(){
        // 1 progress
        // 1 pause
        // 5 progress
        // 1 complete
        self.expect.expectedFulfillmentCount = 11
        
        let remoteFile1 = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        let remoteFile2 = DummyRemoteFile(
            dummyID: TestRemoteFileName.quickSuccess.rawValue
        )
        var subtask1: NewDownloadTaskProtocol? = remoteFile1.downloadTask2
        var subtask2: NewDownloadTaskProtocol? = remoteFile2.downloadTask2
        
        self.downloadTask = NewGroupDownloadTask(
            downloadTasks: [subtask1!, subtask2!],
            hardRefresh: false
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            self.downloadTask?.attemptPause()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) {
            self.downloadTask?.start().start(self.observer)
        }
        
        downloadTask?.start().start(self.observer)
        
        let result = XCTWaiter.wait(for: [self.expect], timeout: 7)
        switch result {
        case .completed:
            XCTAssert(downloadTask?.isComplete == true)
            self.compositeDisposable.dispose()
            subtask1 = nil
            subtask2 = nil
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        case .timedOut: XCTFail("TIMED OUT.")
        default: XCTFail("Failed to complete.")
        }
    }
    
    
    
    // MARK: - TEST PAUSE / RESTART PARALLEL
    func testPauseAndRestartParallel(){
        // 1 progress
        // 1 progress
        // 1 pause
        // 6 progress
        // 1 complete
        self.expect.expectedFulfillmentCount = 13
        
        let remoteFile1 = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        let remoteFile2 = DummyRemoteFile(
            dummyID: TestRemoteFileName.quickSuccess.rawValue
        )
        var subtask1: NewDownloadTaskProtocol? = remoteFile1.downloadTask2
        var subtask2: NewDownloadTaskProtocol? = remoteFile2.downloadTask2
        
//        subtask1?.progressSignal.observe(Signal<Double, Error>.Observer(value: {val in
//            print("inner val: \(val)")
//        }, failed: {error in
//            print("inner failed: \(error)")
//        }, completed: {
//            print("inner complete")
//        }, interrupted: {
//            print("innter interrupted.")
//        }))
        
        self.downloadTask = NewGroupDownloadTask(
            downloadTasks: [subtask1!, subtask2!],
            hardRefresh: false,
            downloadOrder: .parallel
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            self.downloadTask?.attemptPause()
        }
        // FOR SOME REASON THIS FAILS BELOW 2.2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) {
            self.downloadTask?.start().start(self.observer)
        }
        
        downloadTask?.start().start(self.observer)
        
        let result = XCTWaiter.wait(for: [self.expect], timeout: 12)
        switch result {
        case .completed:
            XCTAssert(downloadTask?.isComplete == true)
            self.compositeDisposable.dispose()
            subtask1 = nil
            subtask2 = nil
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        case .timedOut: XCTFail("TIMED OUT.")
        default: XCTFail("Failed to complete.")
        }
    }
    
    
    
    
    // MARK: - TEST BOTH LOCAL SEQ
    func testBothLocalSeq() throws {
        // 1 progress
        // complete
        self.expect.expectedFulfillmentCount = 2
        
        
        // Using a dummy data file as easiest way to save to disk.
        let dummyData1 = DummyLocalData(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        let dummyData2 = DummyLocalData(
            dummyID: TestRemoteFileName.simpleSuccess2.rawValue
        )
        
        try dummyData1.saveToDisk()
        try dummyData2.saveToDisk()
        
        
        
        let remoteFile1 = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        let remoteFile2 = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess2.rawValue
        )
        var subtask1: NewDownloadTaskProtocol? = remoteFile1.downloadTask2
        var subtask2: NewDownloadTaskProtocol? = remoteFile2.downloadTask2
        
        self.downloadTask = NewGroupDownloadTask(
            downloadTasks: [subtask1!, subtask2!],
            hardRefresh: false
        )
        
        downloadTask?.start().start(self.observer)
        
        let result = XCTWaiter.wait(for: [self.expect], timeout: 4)
        switch result {
        case .completed:
            XCTAssert(downloadTask?.isComplete == true)
            self.compositeDisposable.dispose()
            subtask1 = nil
            subtask2 = nil
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        case .timedOut: XCTFail("TIMED OUT.")
        default: XCTFail("Failed to complete.")
        }
    }
    
    // MARK: - TEST BOTH LOCAL PARALLEL
    func testBothLocalParallel() throws {
        // 1 progress
        // complete
        self.expect.expectedFulfillmentCount = 2
        
        
        // Using a dummy data file as easiest way to save to disk.
        let dummyData1 = DummyLocalData(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        let dummyData2 = DummyLocalData(
            dummyID: TestRemoteFileName.simpleSuccess2.rawValue
        )
        
        try dummyData1.saveToDisk()
        try dummyData2.saveToDisk()
        
        
        
        let remoteFile1 = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        let remoteFile2 = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess2.rawValue
        )
        var subtask1: NewDownloadTaskProtocol? = remoteFile1.downloadTask2
        var subtask2: NewDownloadTaskProtocol? = remoteFile2.downloadTask2
        
        self.downloadTask = NewGroupDownloadTask(
            downloadTasks: [subtask1!, subtask2!],
            hardRefresh: false,
            downloadOrder: .parallel
        )
        
        downloadTask?.start().start(self.observer)
        
        let result = XCTWaiter.wait(for: [self.expect], timeout: 2)
        switch result {
        case .completed:
            XCTAssert(downloadTask?.isComplete == true)
            self.compositeDisposable.dispose()
            subtask1 = nil
            subtask2 = nil
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        case .timedOut: XCTFail("TIMED OUT.")
        default: XCTFail("Failed to complete.")
        }
    }
    
    
    // MARK: - TEST HARD REFRESH SEQUENTIAL
    func testHardRefreshSeq() throws {
        // 4 progress
        // 2 progress
        // complete
        self.expect.expectedFulfillmentCount = 8
        
        
        let dummyData1 = DummyLocalData(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        let dummyData2 = DummyLocalData(
            dummyID: TestRemoteFileName.quickSuccess.rawValue
        )
        
        try dummyData1.saveToDisk()
        try dummyData2.saveToDisk()
        
        
        let remoteFile1 = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        let remoteFile2 = DummyRemoteFile(
            dummyID: TestRemoteFileName.quickSuccess.rawValue
        )
        var subtask1: NewDownloadTaskProtocol? = remoteFile1.downloadTask2
        var subtask2: NewDownloadTaskProtocol? = remoteFile2.downloadTask2
        
        self.downloadTask = NewGroupDownloadTask(
            downloadTasks: [subtask1!, subtask2!],
            hardRefresh: true
        )
        
        downloadTask?.start().start(self.observer)
        
        let result = XCTWaiter.wait(for: [self.expect], timeout: 7)
        switch result {
        case .completed:
            XCTAssert(downloadTask?.isComplete == true)
            self.compositeDisposable.dispose()
            subtask1 = nil
            subtask2 = nil
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        case .timedOut: XCTFail("TIMED OUT.")
        default: XCTFail("Failed to complete.")
        }
    }
    
    // MARK: - HARD REFRESH PARALLEL
    func testHardRefreshParallel() throws {
        // 4 progress
        // 4 progress
        // complete
        self.expect.expectedFulfillmentCount = 8
        
        let dummyData1 = DummyLocalData(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        let dummyData2 = DummyLocalData(
            dummyID: TestRemoteFileName.quickSuccess.rawValue
        )
        
        try dummyData1.saveToDisk()
        try dummyData2.saveToDisk()
        
        let remoteFile1 = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        let remoteFile2 = DummyRemoteFile(
            dummyID: TestRemoteFileName.quickSuccess.rawValue
        )
        var subtask1: NewDownloadTaskProtocol? = remoteFile1.downloadTask2
        var subtask2: NewDownloadTaskProtocol? = remoteFile2.downloadTask2
        
        self.downloadTask = NewGroupDownloadTask(
            downloadTasks: [subtask1!, subtask2!],
            hardRefresh: true,
            downloadOrder: .parallel
        )
        
        downloadTask?.start().start(self.observer)
        
        let result = XCTWaiter.wait(for: [self.expect], timeout: 8)
        switch result {
        case .completed:
            XCTAssert(downloadTask?.isComplete == true)
            self.compositeDisposable.dispose()
            subtask1 = nil
            subtask2 = nil
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        case .timedOut: XCTFail("TIMED OUT.")
        default: XCTFail("Failed to complete.")
        }
    }
    
    
    
    // MARK: - TEST ONE LOCAL SEQUENTIAL
    // One local and no hard refresh. Should only download one file.
    func testOneLocalSeq() throws {
        // 4 progress
        // 2 progress
        // complete
        self.expect.expectedFulfillmentCount = 4
        
        
        let dummyData1 = DummyLocalData(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        
        try dummyData1.saveToDisk()
        
        
        let remoteFile1 = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        let remoteFile2 = DummyRemoteFile(
            dummyID: TestRemoteFileName.quickSuccess.rawValue
        )
        var subtask1: NewDownloadTaskProtocol? = remoteFile1.downloadTask2
        var subtask2: NewDownloadTaskProtocol? = remoteFile2.downloadTask2
        
        self.downloadTask = NewGroupDownloadTask(
            downloadTasks: [subtask1!, subtask2!],
            hardRefresh: false
        )
        
        downloadTask?.start().start(self.observer)
        
        let result = XCTWaiter.wait(for: [self.expect], timeout: 7)
        switch result {
        case .completed:
            XCTAssert(downloadTask?.isComplete == true)
            self.compositeDisposable.dispose()
            subtask1 = nil
            subtask2 = nil
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        case .timedOut: XCTFail("TIMED OUT.")
        default: XCTFail("Failed to complete.")
        }
    }
    
    // MARK: - ONE LOCAL PARALLEL
    func testOneLocalParallel() throws {
        // 4 progress
        // 4 progress
        // complete
        self.expect.expectedFulfillmentCount = 4
        
        let dummyData1 = DummyLocalData(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        
        try dummyData1.saveToDisk()
        
        let remoteFile1 = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        let remoteFile2 = DummyRemoteFile(
            dummyID: TestRemoteFileName.quickSuccess.rawValue
        )
        var subtask1: NewDownloadTaskProtocol? = remoteFile1.downloadTask2
        var subtask2: NewDownloadTaskProtocol? = remoteFile2.downloadTask2
        
        self.downloadTask = NewGroupDownloadTask(
            downloadTasks: [subtask1!, subtask2!],
            hardRefresh: false,
            downloadOrder: .parallel
        )
        
        downloadTask?.start().start(self.observer)
        
        let result = XCTWaiter.wait(for: [self.expect], timeout: 8)
        switch result {
        case .completed:
            XCTAssert(downloadTask?.isComplete == true)
            self.compositeDisposable.dispose()
            subtask1 = nil
            subtask2 = nil
            weak var task = self.downloadTask
            self.downloadTask = nil
            XCTAssert(task == nil)
        case .timedOut: XCTFail("TIMED OUT.")
        default: XCTFail("Failed to complete.")
        }
    }
    
}
