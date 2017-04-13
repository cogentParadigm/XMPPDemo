//
//  CDALQuery.swift
//  Pods
//
//  Created by Ali Gangji on 5/1/16.
//
//

import CoreData

open class CDALQuery: NSObject {
    
    var entityName:String
    var predicates = [NSPredicate]()
    var sorts = [NSSortDescriptor]()
    var distinct = false
    var properties = [String]()
    
    public init(entityName:String) {
        self.entityName = entityName
    }
    
    open func from(_ entityName:String) -> CDALQuery {
        self.entityName = entityName
        return self
    }
    
    open func sort(_ key:String, ascending:Bool) -> CDALQuery {
        sorts.append(NSSortDescriptor(key: key, ascending: ascending))
        return self
    }
    
    open func condition(_ predicate:NSPredicate) -> CDALQuery {
        predicates.append(predicate)
        return self
    }
    
    open func distinct(_ value:Bool) {
        distinct = value
    }
    
    open func properties(_ list:[String]) {
        properties.append(contentsOf: list)
    }
    
    open func build() -> NSFetchRequest<NSFetchRequestResult> {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.sortDescriptors = sorts
        if distinct {
            request.returnsDistinctResults = true
            request.resultType = .dictionaryResultType
        }
        if properties.count > 0 {
            request.propertiesToFetch = properties
        }
        if !predicates.isEmpty {
            let conditions = NSCompoundPredicate(type: .and, subpredicates: predicates)
            request.predicate = conditions
        }
        return request
    }
}
