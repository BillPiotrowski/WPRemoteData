//
//  WhereFilter.swift
//  ServerData
//
//  Created by William Piotrowski on 6/16/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import Foundation
import FirebaseFirestore

public struct WhereFilter {
    // Eventually make FieldPath
    let fieldStrings: [String]
    let whereOperator: WhereOperator
    let value: Any?
    
    public init(
        fieldStrings: [String],
        whereOperator: WhereOperator,
        value: Any?
    ){
        self.fieldStrings = fieldStrings
        self.whereOperator = whereOperator
        self.value = value
    }
    
    public init(
        _ fieldString: String,
        _ whereOperator: WhereOperator,
        _ value: Any?
    ){
        let fieldStrings = [fieldString]
        self.init(
            fieldStrings: fieldStrings,
            whereOperator: whereOperator,
            value: value
        )
    }
    
    var fieldPath: FieldPath {
        return FieldPath(fieldStrings)
    }
    
    public func applyTo(query: QueryInterface) -> QueryInterface {
        return WhereOperator.apply(filter: self, toQuery: query)
    }
}


public enum WhereOperator: String {
    case isLessThan = "<"
    case isLessThanOrEqualTo = "<="
    case isEqualTo = "=="
    case isGreaterThan = ">"
    case isGreaterThanOrEqualTo = ">="
    
    static func apply(
        filter: WhereFilter,
        toQuery: QueryInterface
    ) -> QueryInterface {
        switch filter.whereOperator {
        case .isEqualTo:
            return toQuery.whereFieldInterface(filter.fieldStrings, isEqualTo: filter.value as Any)
        case .isGreaterThan:
            return toQuery.whereFieldInterface(filter.fieldStrings, isGreaterThan: filter.value as Any)
        case .isGreaterThanOrEqualTo:
            return toQuery.whereFieldInterface(filter.fieldStrings, isGreaterThanOrEqualTo: filter.value as Any)
        case .isLessThan:
            return toQuery.whereFieldInterface(filter.fieldStrings, isLessThan: filter.value as Any)
        case .isLessThanOrEqualTo:
            return toQuery.whereFieldInterface(filter.fieldStrings, isLessThanOrEqualTo: filter.value as Any)
        }
    }
}

