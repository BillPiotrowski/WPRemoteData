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
    }

    static var allTests = [
        ("testMemoryLeak", testMemoryLeak),
    ]
}
