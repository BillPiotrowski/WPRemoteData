import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(WPRemoteDataTests.allTests),
        testCase(DownloadTaskRootTests.allTests),
    ]
}
#endif
