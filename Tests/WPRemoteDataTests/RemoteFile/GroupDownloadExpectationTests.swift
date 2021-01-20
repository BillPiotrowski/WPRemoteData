import XCTest
@testable import WPRemoteData
import SPCommon
import ReactiveSwift



// Test retain cycle for Download Task and it's inner elements.

/// Tests to verify correct behavior over period of time for remote file download tasks.
///
/// - warning: Any test that does not use the expectation var will  fail.
final class GroupDownloadExpectationTests: DownloadTaskTests {
    
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
        
        self.assertSuccess(timeout: 7)
    }
    
    
    // MARK: - TEST GROUP WITH GROUP SEQUENTIAL
    func testGroupWithGroupSuccessSeq(){
        // 4 progress
        // 4 progress
        // complete
        self.expect.expectedFulfillmentCount = 7
        
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
        
        let subGroup: NewDownloadTaskProtocol = NewGroupDownloadTask(
            downloadTasks: [subtask1!, subtask3!],
            hardRefresh: false
        )
        
        self.downloadTask = NewGroupDownloadTask(
            downloadTasks: [subGroup, subtask2!],
            hardRefresh: false
        )
        
        self.assertSuccess(timeout: 10)
    }
    
    
    // MARK: - TEST GROUP WITH GROUP FAIL SEQUENTIAL
    func testGroupWithGroupFailSeq(){
        // 4 progress
        // 4 progress
        // complete
        self.expect.expectedFulfillmentCount = 4
        
        let remoteFile1 = DummyRemoteFile(
            dummyID: TestRemoteFileName.error.rawValue
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
        
        let subGroup: NewDownloadTaskProtocol = NewGroupDownloadTask(
            downloadTasks: [subtask1!, subtask3!],
            hardRefresh: false
        )
        
        self.downloadTask = NewGroupDownloadTask(
            downloadTasks: [subGroup, subtask2!],
            hardRefresh: false
        )
        
        self.assertFail(timeout: 8)
    }
    
    
    
    // MARK: - TEST GROUP WITH GROUP PARALLEL
    func testGroupWithGroupSuccessParallel(){
        // 4 progress
        // 4 progress
        // complete
        self.expect.expectedFulfillmentCount = 1
        
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
        
        let subGroup: NewDownloadTaskProtocol = NewGroupDownloadTask(
            downloadTasks: [subtask1!, subtask3!],
            hardRefresh: false,
            downloadOrder: .parallel
        )
        
        self.downloadTask = NewGroupDownloadTask(
            downloadTasks: [subGroup, subtask2!],
            hardRefresh: false,
            downloadOrder: .parallel
        )
        
        self.downloadTask?.progressSignal.observeCompleted {
            self.expect.fulfill()
        }
        
        _ = self.downloadTask?.start()
        
        let result = XCTWaiter.wait(
            for: [
                self.expect
            ],
            timeout: 7
        )
        switch result {
        case .completed:
            XCTAssert(downloadTask?.isComplete == true)
        case .timedOut: XCTFail("TIMED OUT.")
        default: XCTFail("Failed to complete.")
        }
        
//        self.assertSuccess(timeout: 10)
    }
    
    
    // MARK: - TEST GROUP WITH GROUP FAIL PARALLEL
    func testGroupWithGroupFailParallel(){
        // 4 progress
        // 4 progress
        // complete
        self.expect.expectedFulfillmentCount = 1
        
        let remoteFile1 = DummyRemoteFile(
            dummyID: TestRemoteFileName.error.rawValue
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
        
        let subGroup: NewDownloadTaskProtocol = NewGroupDownloadTask(
            downloadTasks: [subtask1!, subtask3!],
            hardRefresh: false,
            downloadOrder: .parallel
        )
        
        self.downloadTask = NewGroupDownloadTask(
            downloadTasks: [subGroup, subtask2!],
            hardRefresh: false,
            downloadOrder: .parallel
        )
        
        self.downloadTask?.progressSignal.observeFailed { _ in
            self.expect.fulfill()
        }
        
        _ = self.downloadTask?.start()
        
        let result = XCTWaiter.wait(
            for: [
                self.expect
            ],
            timeout: 7
        )
        switch result {
        case .completed:
            XCTAssert(downloadTask?.isError == true)
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
        
        self.assertSuccess(timeout: 7)
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
        
        self.assertSuccess(timeout: 8)
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
        
        self.assertFail(timeout: 7)
    }
    
    // MARK: - TEST RESTART AFTER FAIL SEQ
    func testRestartAfterFailSeq(){
        // 4 progress
        // 2 progress
        // error
        self.expect.expectedFulfillmentCount = 9
        
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
        
        self.assertRestartAfterError(retryDelay: 6, timeout: 8)
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
        
        self.assertFail(timeout: 7)
    }
    
    
    
    // MARK: - TEST RESTART AFTER FAIL PARALLEL
    func testRestartAfterFailParallel(){
        // 3 progress
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
            hardRefresh: false,
            downloadOrder: .parallel
        )
        
        self.assertRestartAfterError(retryDelay: 6, timeout: 7)
        
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
        
        self.assertCancel(cancelDelay: 3.1, timeout: 7)
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
        
        self.assertCancel(cancelDelay: 1.3, timeout: 7)
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
        
        self.assertPauseAndResume(
            pauseDelay: 1.1,
            restartDelay: 3.1,
            timeout: 7
        )
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
        
        self.downloadTask = NewGroupDownloadTask(
            downloadTasks: [subtask1!, subtask2!],
            hardRefresh: false,
            downloadOrder: .parallel
        )
        
        self.assertPauseAndResume(
            pauseDelay: 1.1,
            restartDelay: 3.1,
            timeout: 12
        )
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
        
        self.assertSuccess(timeout: 4)
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
        
        self.assertSuccess(timeout: 2)
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
        
        self.assertSuccess(timeout: 7)
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
        
        self.assertSuccess(timeout: 8)
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
        
        self.assertSuccess(timeout: 7)
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
        
        self.assertSuccess(timeout: 8)
    }
    
}
