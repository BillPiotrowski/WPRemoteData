//
//  TaskResponseProtocol.swift
//  Scorepio
//
//  Created by William Piotrowski on 2/28/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import Foundation

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
