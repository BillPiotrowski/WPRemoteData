
import XCTest
@testable import WPRemoteData
import ReactiveSwift





final class GetAllListenableTests: XCTestCase {
    private var disposable1: Disposable? = nil
    private var disposable2: Disposable? = nil
    private let testLocation = TestLocation()
    private lazy var ref: DummyCollectionReference = { testLocation.collectionReference as! DummyCollectionReference
    }()
    private lazy var database: DummyDatabase = {
        TestLocation.database as! DummyDatabase
    }()
    
    
    
    // MARK: -
    // MARK: TEAR DOWN
    override func tearDownWithError() throws {
        database.reset()
        self.disposable1?.dispose()
        self.disposable2?.dispose()
        self.disposable1 = nil
        self.disposable2 = nil
    }
    
    
    
    // MARK: -
    // MARK: TEST NOT DISPOSED
    
    /// Creates two signals and does not dispose of signals or Firestore Listeners. Asserts that firestore listeners are still active.
    ///
    /// Will not dispose evena after disposing of Signal.
    func testGetAllListenersNotDisposed() throws {
        let exp = expectation(description: "Test after 5 seconds")
        exp.expectedFulfillmentCount = 2
        
        XCTAssert(!ref.hasActiveListener)
        
        let (_, signal1) = testLocation.collectionReference.addListener()
        let (_, signal2) = testLocation.collectionReference.addListener()
        
        
        self.disposable1 = signal1.observeValues{ _ in
            self.disposable1?.dispose()
            exp.fulfill()
        }
        
        self.disposable2 = signal2.observeValues{ _ in
            self.disposable2?.dispose()
            exp.fulfill()
        }
        
        XCTAssert(ref.hasActiveListener)
        
        let result = XCTWaiter.wait(for: [exp], timeout: 3.0)
        switch result {
        case .completed: XCTAssert(ref.hasActiveListener)
        case .incorrectOrder: XCTFail("ORDER")
        case .interrupted: XCTFail("INT")
        case .invertedFulfillment: XCTFail("INV")
        case .timedOut:XCTFail("TIMED")
        @unknown default:
            XCTFail("??")
        }
        
    }
    
    // MARK: -
    // MARK: TEST 1 of 2 DISPOSED
    
    func testGet1ListenerDisposed() throws {
        let exp = expectation(description: "Test after 5 seconds")
        exp.expectedFulfillmentCount = 2
        
        XCTAssert(!ref.hasActiveListener)
        
        let (listener1, signal1) = testLocation.collectionReference.addListener()
        let (_, signal2) = testLocation.collectionReference.addListener()
        
        
        self.disposable1 = signal1.observeValues{ _ in
            listener1.remove()
            exp.fulfill()
        }
        
        self.disposable2 = signal2.observeValues{ _ in
            exp.fulfill()
        }
        
        XCTAssert(ref.hasActiveListener)
        
        let result = XCTWaiter.wait(for: [exp], timeout: 3.0)
        switch result {
        case .completed: XCTAssert(ref.hasActiveListener)
        case .incorrectOrder: XCTFail("ORDER")
        case .interrupted: XCTFail("INT")
        case .invertedFulfillment: XCTFail("INV")
        case .timedOut:XCTFail("TIMED")
        @unknown default:
            XCTFail("??")
        }
        
    }
    
    
    
    
    // MARK: -
    // MARK: TEST PROPER
    func testSingleProperDisposal() throws {
        let exp = expectation(description: "Test after 5 seconds")
        exp.expectedFulfillmentCount = 1
        
        XCTAssert(!ref.hasActiveListener)
        
        let (listener1, signal1) = testLocation.collectionReference.addListener()
        
        self.disposable1 = signal1.observeValues{ _ in
            listener1.remove()
            exp.fulfill()
        }
        
        XCTAssert(ref.hasActiveListener)
        
        let result = XCTWaiter.wait(for: [exp], timeout: 3.0)
        switch result {
        case .completed: XCTAssert(!ref.hasActiveListener)
        case .incorrectOrder: XCTFail("ORDER")
        case .interrupted: XCTFail("INT")
        case .invertedFulfillment: XCTFail("INV")
        case .timedOut:XCTFail("TIMED")
        @unknown default:
            XCTFail("??")
        }
    }
    
    
    
    // MARK: -
    // MARK: FIX? SIMULATE INTERRUPTION
    /// Simulating situation where signal is not retained. Ideally, the signal would be interrupted at that point and release the Listener, but it is not happening as desired.
    func testInterruption() throws {
        
        XCTAssert(!ref.hasActiveListener)
        
        var (_, signal1): (
            ListenerRegistrationInterface,
            (Signal<(QuerySnapshotInterface?, Error?), Never>)?
        )  = testLocation.collectionReference.addListener()
        
        XCTAssert(ref.hasActiveListener)
        
        signal1 = nil
        // THIS SHOULD NOT BE TRUE
        XCTAssert(ref.hasActiveListener)
        XCTAssert(signal1 == nil)
        
    }
    
    
    

    static var allTests = [
        ("testGetAllListenersNotDisposed", testGetAllListenersNotDisposed),
    ]
}
