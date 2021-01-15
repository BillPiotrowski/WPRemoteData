//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/15/21.
//

import Foundation

// MARK: APPLY FILTERS
extension QueryInterface {
    
    /// Applies filters if they exist and returns `self` as `QueryInterface`.
    func getQuery(
        from filters: [WhereFilter]? = nil
    ) -> QueryInterface{
        guard let filters = filters
        else {
            return self
        }
        return self.apply(filters: filters)
    }
    
    /// Applies filters to self.
    private func apply(
        filters: [WhereFilter]
    ) -> QueryInterface {
        var temp: QueryInterface = self
        for filter in filters {
            temp = temp.apply(filter: filter)
        }
        return temp
    }
    
    /// Applies a single filter to query.
    /// - Parameter filter: `WhereFilter` which help to define filters in a struct.
    /// - Returns: returns `self` as `QueryInterface` with filter applied.
    private func apply(
        filter: WhereFilter
    ) -> QueryInterface {
        switch filter.whereOperator {
        case .isEqualTo:
            print("INSIDE IS EQUAL TO: \(filter.fieldStrings)")
            return self.whereFieldInterface(
                filter.fieldStrings,
                isEqualTo: filter.value as Any
            )
        case .isGreaterThan:
            return self.whereFieldInterface(
                filter.fieldStrings,
                isGreaterThan: filter.value as Any
            )
        case .isGreaterThanOrEqualTo:
            return self.whereFieldInterface(
                filter.fieldStrings,
                isGreaterThanOrEqualTo: filter.value as Any
            )
        case .isLessThan:
            return self.whereFieldInterface(
                filter.fieldStrings,
                isLessThan: filter.value as Any
            )
        case .isLessThanOrEqualTo:
            return self.whereFieldInterface(
                filter.fieldStrings,
                isLessThanOrEqualTo: filter.value as Any
            )
        }
    }
    
}
