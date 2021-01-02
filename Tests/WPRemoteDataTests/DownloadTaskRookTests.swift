import XCTest
@testable import WPRemoteData

final class DownloadTaskRootTests: XCTestCase {
    func testMemoryLeak() {
        // ARRANGE
        var downloadTask: DownloadTaskRoot? = DownloadTaskRoot(handler: {status, snapshot in
            
        })
        weak var leakRef = downloadTask
        
        // ACT
        downloadTask = nil
        
        // ASSERT
        XCTAssert(leakRef == nil)
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        //XCTAssertEqual(true)
    }

    static var allTests = [
        ("testMemoryLeak", testMemoryLeak),
    ]
}
