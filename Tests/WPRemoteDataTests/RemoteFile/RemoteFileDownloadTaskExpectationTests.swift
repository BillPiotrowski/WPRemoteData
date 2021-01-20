import XCTest
@testable import WPRemoteData
import SPCommon
import ReactiveSwift



// Test retain cycle for Download Task and it's inner elements.

/// Tests to verify correct behavior over period of time for remote file download tasks.
///
/// - warning: Any test that does not use the expectation var will  fail.
final class RemoteFileDownloadTaskExpectationTests: DownloadTaskTests {
    
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
        self.expect.expectedFulfillmentCount = 4
        
        let remoteFile = DummyRemoteFile(
            dummyID: TestRemoteFileName.error.rawValue
        )
        self.downloadTask = remoteFile.downloadTask2
        
        self.assertFail(timeout: 3.0)
    }
    
    
    // MARK: - RESTART AFTER ERROR
    func testRestartAfterFail() throws {
        self.expect.expectedFulfillmentCount = 5
        
        let remoteFile = DummyRemoteFile(
            dummyID: TestRemoteFileName.error.rawValue
        )
        self.downloadTask = remoteFile.downloadTask2
        
        self.assertRestartAfterError(retryDelay: 3, timeout: 4)
    }
    
    // MARK: - SIMPLE SUCCESS
    func testSimpleSuccess() throws {
        self.expect.expectedFulfillmentCount = 6
        
        let remoteFile = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        self.downloadTask = remoteFile.downloadTask2
        
        self.assertSuccess(timeout: 6.5)
    }
    
    // MARK: - CANCEL
    // Should Download task signal of signals complete after error? interrupt?
    func testCancel() throws {
        self.expect.expectedFulfillmentCount = 5
        
        let remoteFile = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        self.downloadTask = remoteFile.downloadTask2
        
        self.assertCancel(cancelDelay: 1.6, timeout: 4)
    }
    
    
    
    // MARK: - PAUSE AND RESUME
    /// Begins the download and after two progress updates, it pauses. Then resumes after 3 seconds.
    func testPauseAndResume() throws {
        // 2 progress
        // 1 pause
        // 3 progress
        // complete
        self.expect.expectedFulfillmentCount = 9
        
        let remoteFile = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        self.downloadTask = remoteFile.downloadTask2
        
        self.assertPauseAndResume(pauseDelay: 1.1, restartDelay: 1.5, timeout: 10)
    }
    
    
    
    // MARK: - TEST SECOND START AFTER COMPLETION
    /// Expected to immediately send two events: a value (1.0) and a completion event after attempting to start a completed download.
    func testStartAfterComplete() throws {
        // 5 for the initial complete and 2 for the restart complete
        self.expect.expectedFulfillmentCount = 8
        
        let remoteFile = DummyRemoteFile(
            dummyID: TestRemoteFileName.simpleSuccess.rawValue
        )
        self.downloadTask = remoteFile.downloadTask2
        
        self.assertStartAfterSuccess(retryDelay: 3.0, timeout: 6.5)
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
        
        self.assertSuccess(timeout: 2.5)
    }
    
    
    // MARK: - HARD REFRESH
    /// Expected to create a normal download request with 5 status updates even though the file is local because hard refresh is selected.
    func testHardRefresh() throws {
        self.expect.expectedFulfillmentCount = 6
        
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
        
        self.assertSuccess(timeout: 3.5)
        
    }
    
    
}
