import XCTest
@testable import WPRemoteData
import SPCommon
import ReactiveSwift





// Test retain cycle for Download Task and it's inner elements.

/// Tests to verify correct behavior over period of time for remote file download tasks.
///
/// - warning: Any test that does not use the expectation var will  fail.
final class RemoteDataDownloadTaskExpectations: DownloadTaskTests {
    
    
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
    
    // MARK: - TEST SUCCESS
    func testSuccess(){
        self.expect.expectedFulfillmentCount = 3
        
        let remoteDoc = TestDocument(
            testDataID: DummyDataDocID.quickSuccess.rawValue
        )
        self.downloadTask = remoteDoc.downloadTask
        
        self.assertSuccess(timeout: 2)
        
    }
    
    // MARK: - TEST FAILURE
    func testFailure(){
        self.expect.expectedFulfillmentCount = 2
        
        let remoteDoc = TestDocument(
            testDataID: DummyDataDocID.failure.rawValue
        )
        self.downloadTask = remoteDoc.downloadTask
        
        self.assertFail(timeout: 3)
    }
    
    
    // MARK: - TEST CANCEL
    func testCancel(){
        self.expect.expectedFulfillmentCount = 2
        
        let remoteDoc = TestDocument(
            testDataID: DummyDataDocID.failure.rawValue
        )
        self.downloadTask = remoteDoc.downloadTask
        
        self.assertCancel(
            cancelDelay: 0.8,
            timeout: 2
        )
    }
    
    
    // MARK: - TEST PAUSE AND RESUME
    func testPauseAndResume(){
        self.expect.expectedFulfillmentCount = 4
        
        let remoteDoc = TestDocument(
            testDataID: DummyDataDocID.quickSuccess.rawValue
        )
        self.downloadTask = remoteDoc.downloadTask
        
        self.assertPauseAndResume(
            pauseDelay: 0.8,
            restartDelay: 2,
            timeout: 4
        )
        
    }
    
    
    // MARK: - START AFTER SUCCESS
    func testStartAfterSuccess(){
        self.expect.expectedFulfillmentCount = 5
        
        let remoteDoc = TestDocument(
            testDataID: DummyDataDocID.quickSuccess.rawValue
        )
        self.downloadTask = remoteDoc.downloadTask
    
        self.assertStartAfterSuccess(retryDelay: 2, timeout: 5)
        
    }
    
    
    // MARK: - TEST ALREADY LOCAL
    func testAlreadyLocal() throws {
        self.expect.expectedFulfillmentCount = 2
        
        let remoteDoc = TestDocument(
            testDataID: DummyDataDocID.quickSuccess.rawValue
        )
        
        // SAVE TO LOCAL
        try remoteDoc.localDocument.archive(dictionary: [:])
        
        self.downloadTask = remoteDoc.downloadTask
        
        // ASSERT
        self.assertSuccess(timeout: 2)
        
    }
    
    // MARK: - TEST HARD REFRESH
    func testHardRefresh() throws {
        self.expect.expectedFulfillmentCount = 3
        
        let remoteDoc = TestDocument(
            testDataID: DummyDataDocID.quickSuccess.rawValue
        )
        
        // SAVE TO LOCAL
        try remoteDoc.localDocument.archive(dictionary: [:])
        
        self.downloadTask = remoteDoc.downloadTask(hardRefresh: true)
        
        // ASSERT
        self.assertSuccess(timeout: 2)
        
    }
    
    
    // MARK: - TEST RESTART AFTER FAIL
    func testRestartAfterFail() throws {
        self.expect.expectedFulfillmentCount = 3
        
        let remoteDoc = TestDocument(
            testDataID: DummyDataDocID.failure.rawValue
        )
        
        self.downloadTask = remoteDoc.downloadTask(hardRefresh: true)
        
        // ASSERT
        self.assertRestartAfterError(retryDelay: 3, timeout: 7)
        
    }

}
