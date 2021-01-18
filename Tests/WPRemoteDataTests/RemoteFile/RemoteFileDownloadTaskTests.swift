import XCTest
@testable import WPRemoteData
import ReactiveSwift
import SPCommon

struct DummyRemoteFileFolder: RemoteFileFolderProtocol {
    var remoteFileType: RemoteFileProtocol.Type = DummyRemoteFile.self
    
    let name: String = "tests"
    
    
}

struct DummyLocalFolder: LocalDirectory {
    let name: String = "tests"
    
    
}

struct DummyLocalFile: LocalFile {
    let dummyID: String
    var directory: LocalDirectory = DummyLocalFolder()
    
    var name: String { dummyID }
    
}

struct DummyRemoteFile: RemoteFileProtocol {
    let  dummyID: String
    let location: RemoteFileFolderProtocol = DummyRemoteFileFolder()
    var name: String { dummyID }
    
    var localFile: LocalFile { DummyLocalFile(dummyID: dummyID) }
    
    
    
}

// Test hard refresh
// Test pause / restart
// Test already local (same as hard refresh?)
// Test complete and attempt to restart.
// Test simple multiple prog then success

final class RemoteFileDownloadTaskTests: XCTestCase {
    
    
    override func setUpWithError() throws {
        ServerAppStarter.configure(ServerAppStarter.Config(forTesting: true))
    }
    
    
    func test1() throws {
        let exp = expectation(description: "Test after 5 seconds")
        exp.expectedFulfillmentCount = 3
        
        let remoteFile = DummyRemoteFile(
            dummyID: DummyStorageReferenceInterface.FileName.error.rawValue
        )
        let downloadTask2 = remoteFile.downloadTask2
        downloadTask2.start()
        .start(Signal<Double, Error>.Observer(
            value: {val in
                exp.fulfill()
            },
            failed: {error in
//                XCTAssert(downloadTask2.state == .failure(error: error))
                exp.fulfill()
            },
            completed: {
                exp.fulfill()
            },
            interrupted: {
                exp.fulfill()
            }
        ))
//        downloadTask2.stateProperty.producer.startWithValues{
//            print("SIGNAL UPDATE: \($0)")
//            exp.fulfill()
//        }
//
        
        
        let result = XCTWaiter.wait(for: [exp], timeout: 3.0)
        switch result {
        case .completed: XCTAssert(true)
        case .incorrectOrder: XCTFail("ORDER")
        case .interrupted: XCTFail("INT")
        case .invertedFulfillment: XCTFail("INV")
        case .timedOut:XCTFail("TIMED")
        @unknown default:
            XCTFail("??")
        }
    }
    
    // Should Download task signal of signals complete after error? interrupt?
    func testSimpleSuccess() throws {
        let exp = expectation(description: "Test after 5 seconds")
        exp.expectedFulfillmentCount = 5
        
        let remoteFile = DummyRemoteFile(
            dummyID: DummyStorageReferenceInterface.FileName.simpleSuccess.rawValue
        )
        let downloadTask = remoteFile.downloadTask2
        downloadTask.stateProperty.producer.startWithValues { _ in
            print("ROOT PROG: \(downloadTask.progress.fractionCompleted)")
        }
        
        downloadTask.start()
        .start(Signal<Double, Error>.Observer(
            value: {val in
                print("PROGRESS: \(val)")
                XCTAssert(val == downloadTask.progress.fractionCompleted)
                XCTAssert(downloadTask.state == .loading)
                exp.fulfill()
            },
            failed: {error in
                print("ERROR: \(error)")
                XCTAssert(downloadTask.state.isError)
                exp.fulfill()
            },
            completed: {
                print("COMPLETE")
                XCTAssert(downloadTask.state == .complete)
                exp.fulfill()
            },
            interrupted: {
                print("Interrupted")
                XCTAssert(downloadTask.state == .paused)
                exp.fulfill()
            }
        ))
        
        
        let result = XCTWaiter.wait(for: [exp], timeout: 6.5)
        switch result {
        case .completed: XCTAssert(downloadTask.state == .complete)
        case .incorrectOrder: XCTFail("ORDER")
        case .interrupted: XCTFail("INT")
        case .invertedFulfillment: XCTFail("INV")
        case .timedOut:XCTFail("TIMED")
        @unknown default:
            XCTFail("??")
        }
    }
    
    // Should Download task signal of signals complete after error? interrupt?
    func testCancel() throws {
        let exp = expectation(description: "Test after 5 seconds")
        exp.expectedFulfillmentCount = 4
        
        let remoteFile = DummyRemoteFile(
            dummyID: DummyStorageReferenceInterface.FileName.simpleSuccess.rawValue
        )
        let downloadTask = remoteFile.downloadTask2
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            downloadTask.cancel()
        }
        downloadTask.start()
        .start(Signal<Double, Error>.Observer(
            value: {val in
                print("PROGRESS: \(val)")
                XCTAssert(downloadTask.state == .loading)
                exp.fulfill()
            },
            failed: {error in
                print("ERROR: \(error)")
                XCTAssert(downloadTask.state.isError)
                exp.fulfill()
            },
            completed: {
                print("COMPLETE")
                XCTAssert(downloadTask.state == .complete)
                exp.fulfill()
            },
            interrupted: {
                print("Interrupted")
                XCTAssert(downloadTask.state == .paused)
                exp.fulfill()
            }
        ))
        
        
        let result = XCTWaiter.wait(for: [exp], timeout: 4)
        switch result {
        case .completed: XCTAssert(downloadTask.state.isError)
        case .incorrectOrder: XCTFail("ORDER")
        case .interrupted: XCTFail("INT")
        case .invertedFulfillment: XCTFail("INV")
        case .timedOut:XCTFail("TIMED")
        @unknown default:
            XCTFail("??")
        }
    }
    
    
    
//    func testPause() throws {
//        let exp = expectation(description: "Test after 5 seconds")
//        exp.expectedFulfillmentCount = 4
//        
//        let remoteFile = DummyRemoteFile(
//            dummyID: DummyStorageReferenceInterface.FileName.simpleSuccess.rawValue
//        )
//        let downloadTask = remoteFile.downloadTask2
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
//            downloadTask.pause()
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//            downloadTask.start()
//        }
//        downloadTask.start()
//        .start(Signal<Double, Error>.Observer(
//            value: {val in
//                print("PROGRESS: \(val)")
//                XCTAssert(downloadTask.state == .loading)
//                exp.fulfill()
//            },
//            failed: {error in
//                print("ERROR: \(error)")
//                XCTAssert(downloadTask.state.isError)
//                exp.fulfill()
//            },
//            completed: {
//                print("COMPLETE")
//                XCTAssert(downloadTask.state == .complete)
//                exp.fulfill()
//            },
//            interrupted: {
//                print("Interrupted")
//                XCTAssert(downloadTask.state == .paused)
//                exp.fulfill()
//            }
//        ))
//        
//        
//        let result = XCTWaiter.wait(for: [exp], timeout: 10)
//        switch result {
//        case .completed: XCTAssert(downloadTask.state.isError)
//        case .incorrectOrder: XCTFail("ORDER")
//        case .interrupted: XCTFail("INT")
//        case .invertedFulfillment: XCTFail("INV")
//        case .timedOut:XCTFail("TIMED")
//        @unknown default:
//            XCTFail("??")
//        }
//    }
//    
    
    
}
