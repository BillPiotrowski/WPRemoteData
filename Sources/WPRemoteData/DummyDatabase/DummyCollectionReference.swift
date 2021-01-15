//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/14/21.
//

import Foundation

class DummyCollectionReference {
    /// The path of the collection relative to the root of the database.
    let path: String
    
    /// An array of query filters as strings.
    ///
    /// - note: `property1==value1`
    internal private (set) var query = [String]()
    
    /// A collections of listeners stored by their hash as key. Value contains a DummyDisposable and its relative listener enclosure.
    ///
    /// - important: DummyDisposal will dispose, but not actually prevent enclosure from being called.
    ///
    /// Could possible add that feature in future, but does not seem important for testing purposes. Mainly looking at retain cycles and proper release. Not actual functionality.
    internal private (set) var listeners: [Int: (DummyDisposable, (QuerySnapshotInterface?, Error?) -> Void)] = [:]
    
    
    init(path: String){
        self.path = path
    }
}


// MARK: -
// MARK: CONFORM: CollectionReferenceInterface
extension DummyCollectionReference: CollectionReferenceInterface {
    func documentInterface() -> DocumentReferenceInterface {
        DummyDocumentReference(collectionReference: self)
    }
    
    func documentInterface(
        _ documentPath: String
    ) -> DocumentReferenceInterface {
        DummyDocumentReference(
            collectionReference: self,
            relativePath: documentPath
        )
    }
    
    
}

// MARK: -
// MARK: CONFORM: QueryInterface
extension DummyCollectionReference: QueryInterface {
    
    func whereFieldInterface(
        _ fields: [String],
        isEqualTo: Any
    ) -> QueryInterface {
        for field in fields {
            self.query.append("\(field)==\(unwrap(any: isEqualTo))")
        }
        return self
    }
    
    func whereFieldInterface(
        _ fields: [String],
        isGreaterThan: Any
    ) -> QueryInterface {
        for field in fields {
            self.query.append("\(field)>\(unwrap(any: isGreaterThan))")
        }
        return self

    }
    
    func whereFieldInterface(
        _ fields: [String],
        isGreaterThanOrEqualTo: Any
    ) -> QueryInterface {
        for field in fields {
            self.query.append("\(field)>=\(unwrap(any: isGreaterThanOrEqualTo))")
        }
        return self
    }
    
    func whereFieldInterface(
        _ fields: [String],
        isLessThan: Any
    ) -> QueryInterface {
        for field in fields {
            self.query.append("\(field)<\(unwrap(any: isLessThan))")
        }
        return self
    }
    
    func whereFieldInterface(
        _ fields: [String],
        isLessThanOrEqualTo: Any
    ) -> QueryInterface {
        for field in fields {
            self.query.append("\(field)<=\(unwrap(any: isLessThanOrEqualTo))")
        }
        return self
    }
    
    func getDocumentsInterface(
        completion: @escaping (QuerySnapshotInterface?, Error?) -> Void
    ) {
        completion(nil, NSError(domain: "no docs", code: 1))
    }
    
    /// Sends a dummy error after 1 second.
    open func addSnapshotListenerInterface(
        _ listener: @escaping (QuerySnapshotInterface?, Error?) -> Void
    ) -> ListenerRegistrationInterface {
        let firebaseListener = DummyDisposable(){}
        
        // Test listener will dispose, but does actually prevent the enclosure from being called.
        self.listeners[firebaseListener.hash] = (
            firebaseListener,
            listener
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            listener(nil, NSError(domain: "asdf", code: 2))
        }
        
        return firebaseListener
    }
    
    
}


// MARK: -
// MARK: TESTING HELPERS
extension DummyCollectionReference {
    
    /// Returns a query string of the applied filters in the style of a URL GET. Does not include root url or initial `?`.
    var queryString: String? {
        guard query.count > 0
        else { return nil }
        return self.query.joined(separator: "&")
    }
    
    /// A String that represents the relative url to the database. Begins with collection location and if there is a query string, returns that as well formated as a URL GET.
    ///
    /// - note:
    ///
    /// example: location?property1==value1&property2>=value2
    var relativeURLString: String {
        guard let queryString = queryString
        else { return path }
        return "\(path)?\(queryString)"
    }
    
    /// Database is a singleton, so unit tests retain between tests.
    ///
    /// Reset allows opportunity to dispose and reset stored listeners.
    func reset(){
        self.listeners = [:]
    }
    
    /// Returns true if there are any active (non-disposed) listeners
    var hasActiveListener: Bool {
        for listener in self.listeners.values {
            guard listener.0.isComplete
            else { return true }
        }
        return false
    }
    
    /// The integer count of all non-disposed listeners.
    var activeListenerCount: Int {
        var i: Int = 0
        for listener in self.listeners.values {
            guard !listener.0.isComplete
            else { continue }
            i += 1
        }
        return i
    }
}

// MARK: -
// MARK: HELPER
extension DummyCollectionReference {
    /// Takes `Any` that can be optional an allows it to be printed unwrapped.
    ///
    /// - note: Not sure how this works.
    ///
    /// - Parameter any: A value of `Any`.
    /// - Returns: Returns a value of `Any` that does not print as `Optional()`.
    ///
    /// A value of `nil` returns as `<null>`
    ///
    /// - author: https://stackoverflow.com/questions/27989094/how-to-unwrap-an-optional-value-from-any-type
    private func unwrap(any:Any) -> Any {
        
        let mi = Mirror(reflecting: any)
        if mi.displayStyle != .optional {
            return any
        }

        if mi.children.count == 0 { return NSNull() }
        let (_, some) = mi.children.first!
        return some

    }
}
