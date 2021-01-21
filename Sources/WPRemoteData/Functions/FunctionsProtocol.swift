//
//  FunctionsProtocol.swift
//  Scorepio
//
//  Created by William Piotrowski on 6/30/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import SPCommon
import FirebaseFunctions
import Promises

struct Dummy: _Data {
    var dictionary: [String : Any] = [:]
    
    
    init(dictionary: [String : Any]) throws {
        
    }
    
    
}


public protocol FirebaseFunctionProtocol {
    var functionName: String { get }
    var input: WriteableData { get }
}

// MARK: PRIVATE METHODS
extension FirebaseFunctionProtocol {
    public var httpCallable: HTTPSCallable {
        return Self.functions.httpsCallable(self.functionName)
    }
}

// MARK: PUBLIC
extension FirebaseFunctionProtocol {
    static var functions: Functions {
        return Functions.functions()
    }
    
    
    public func call(
        completion: ((TaskResponse) -> Void)?
    ){
        httpCallable.call(input.dictionary, completion: { (result, error) in
            guard let completion = completion else { return }
            let dictionary: [String: Any]?
            let responseError: Error?
            
            if let result = result {
                do {
                    dictionary = try Dummy.asStringAny(value: result.data, key: "data", initializer: "httpCallableResult")
                    responseError = nil
                } catch {
                    dictionary = nil
                    responseError = error
                }
            } else {
                dictionary = nil
                responseError = FirebaseFunctionError2.returnDataIsNotDictionary
            }
            let taskReturn = TaskResponse(
                error: error ?? responseError,
                dictionary: dictionary
            )
            completion(taskReturn)
        })
    }
}

// MARK: CALL PROMISE
extension FirebaseFunctionProtocol {
    func call() -> Promise<Any>{
        return Promise { fulfill, reject in
            httpCallable.call(
                input.dictionary
            ){ (result, error) in
                guard let data = result?.data
                    else {
                        reject(error ?? FirebaseFunctionError2.missingReturnData)
                        return
                }
                fulfill(data)
            }
        }
    }
}

public enum FirebaseFunctionError2: ScorepioError {
    case missingReturnData
    case returnDataIsNotDictionary
    public var message: String {
        switch self {
        case .missingReturnData: return "The response from HTTP call does not contain data."
        case .returnDataIsNotDictionary: return "The data object in the http callable response did not conform to dictionary [String:Any]."
        }
    }
}

public struct TaskResponse: TaskReturn {
    public let error: Error?
    let dictionary: [String:Any]?
    public var returnItem: Any? {
        return self.dictionary
    }
}




/*





/// Protocol for Task returns. Should be used any time there is a delayed callback and the potential for erros. Should be used similar to throwable functions.
public protocol TaskReturn {
    var error: Error? { get }
    var returnItem: Any? { get }
}

extension TaskReturn {
    /// Returns true if there is no high-level error.
    var success: Bool {
        return error == nil
    }
    /// Returns true if a high-level error exists.
    var failure: Bool {
        return error != nil
    }
    
    /// Returns single level of child tasks if there is any array.
    var childReturnItems: [TaskReturn]? {
        return Self.childReturnItems(taskReturn: self)
    }
    
    /// Returns all task items including itself and any children (recursive)
    var allTaskItems: [TaskReturn] {
        return Self.allTaskItems(taskReturn: self)
    }
    /// Returns single level of child tasks if there is any array.
    static func childReturnItems(
        taskReturn: TaskReturn
    ) -> [TaskReturn]? {
        guard let returnItemArray = taskReturn.returnItem as? [TaskReturn]
            else { return nil }
        return returnItemArray
    }
    
    // double check recursive
    /// Returns all task items including itself and any children (recursive)
    static func allTaskItems(
        taskReturn: TaskReturn
    ) -> [TaskReturn] {
        var allTaskItems = [taskReturn]
        if let children = Self.childReturnItems(taskReturn: taskReturn) {
            for child in children {
                let allChildTaskItems = Self.allTaskItems(
                    taskReturn: child
                )
                allTaskItems.append(contentsOf: allChildTaskItems)
            }
        }
        return allTaskItems
    }
}
*/

