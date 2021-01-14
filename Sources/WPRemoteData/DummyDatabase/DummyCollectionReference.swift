//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/14/21.
//

import Foundation

class DummyCollectionReference {
    let path: String
    internal private (set) var query = [String]()
    internal private (set) var hasListener: Bool = false
    
    init(path: String){
        self.path = path
    }
}

// MARK: -
// MARK: TESTING HELPERS
extension DummyCollectionReference {
    var queryString: String? {
        guard query.count > 0
        else { return nil }
        return self.query.joined(separator: "&")
    }
    var relativeURL: String {
        guard let queryString = queryString
        else { return path }
        return "\(path)?\(queryString)"
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
    
    func addSnapshotListenerInterface(
        _ listener: @escaping (QuerySnapshotInterface?, Error?) -> Void
    ) -> ListenerRegistrationInterface {
        print("INSIDE ADDNG!!")
        self.hasListener = true
        let disposable = DummyDisposable(){
            self.hasListener = false
        }
//        listener(nil, NSError(domain: "no docs", code: 1))
        return disposable
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
