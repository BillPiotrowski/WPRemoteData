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
    
    public func applyTo(query: Query) -> Query {
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
        toQuery: Query
    ) -> Query {
        switch filter.whereOperator {
        case .isEqualTo:
            return toQuery.whereField(filter.fieldPath, isEqualTo: filter.value as Any)
        case .isGreaterThan:
            return toQuery.whereField(filter.fieldPath, isGreaterThan: filter.value as Any)
        case .isGreaterThanOrEqualTo:
            return toQuery.whereField(filter.fieldPath, isGreaterThanOrEqualTo: filter.value as Any)
        case .isLessThan:
            return toQuery.whereField(filter.fieldPath, isLessThan: filter.value as Any)
        case .isLessThanOrEqualTo:
            return toQuery.whereField(filter.fieldPath, isLessThanOrEqualTo: filter.value as Any)
        }
    }
}

