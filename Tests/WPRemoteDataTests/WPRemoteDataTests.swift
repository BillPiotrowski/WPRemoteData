import XCTest
@testable import WPRemoteData
import ReactiveSwift





final class WPRemoteDataTests: XCTestCase {
    private var disposable1: Disposable? = nil
    private var disposable2: Disposable? = nil
    private let testLocation = TestLocation()
    private lazy var ref: DummyCollectionReference = { testLocation.collectionReference as! DummyCollectionReference
    }()
    
    
    override func tearDownWithError() throws {
    }
    
    func testLocationPath() throws {
        let testLocation = TestLocation()
        testLocation.getAll().then {_ in}.catch{_ in}
        XCTAssert(testLocation.path == "testCollection")
    }
    
    func testDocumentPath() throws {
        let testDataID = TestLocation().generateDocumentID()
        let testDoc = TestDocument(testDataID: testDataID)
        
        XCTAssert(testDoc.path == "testCollection/\(testDataID)")
    }
    
    func testQueryString() throws {
        let testLocation = TestLocation()
        
        
        let filters = [
            WhereFilter("property1", .isEqualTo, nil),
            WhereFilter("property2", .isGreaterThan, "value2"),
            WhereFilter("property3", .isGreaterThanOrEqualTo, "value3"),
            WhereFilter("property4", .isLessThan, "value4"),
            WhereFilter("property5", .isLessThanOrEqualTo, 0),
        ]
        testLocation.getAll(filters: filters).then {_ in}.catch{_ in}
//        testLocation.getAllData(filters: filters)
//            .then{_ in}.catch{ _ in}
        
        let collectionRef = testLocation.collectionReference as! DummyCollectionReference
        
        XCTAssert(collectionRef.relativeURLString == "testCollection?property1==<null>&property2>value2&property3>=value3&property4<value4&property5<=0")
        
    }
    
    
    static var allTests = [
        ("testQueryString", testQueryString),
    ]
}
