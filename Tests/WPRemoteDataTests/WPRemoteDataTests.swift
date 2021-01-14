import XCTest
@testable import WPRemoteData





final class WPRemoteDataTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        
        let testLocation = TestLocation()
        testLocation.getAll().done{ _ in
            
        }.catch { _ in
            
        }
        let disposable = testLocation.addListener()
        let collectionRef = testLocation.collectionReference as! DummyCollectionReference
        XCTAssert(collectionRef.hasListener)
        disposable.disposable.remove()
        XCTAssert(!collectionRef.hasListener)
        XCTAssert(testLocation.path == "testCollection")
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
        testLocation.getAll(filters: filters)
            .done{_ in}.catch{ _ in}
        
        let collectionRef = testLocation.collectionReference as! DummyCollectionReference
        
        XCTAssert(collectionRef.relativeURL == "testCollection?property1==<null>&property2>value2&property3>=value3&property4<value4&property5<=0")
        
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
