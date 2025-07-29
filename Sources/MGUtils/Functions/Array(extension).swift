//
//  Array(extension).swift
//  PandaHead
//
//  Created by ZhenShan Dong on 2021/6/18.
//  Copyright © 2021 HongYeGroup. All rights reserved.
//

import Foundation
extension Array{
    /// 去重
   public func filterDuplicates<E: Equatable>(_ filter: (Element) -> E) -> [Element] {
        var result = [Element]()
        for value in self {
            let key = filter(value)
            if !result.map({filter($0)}).contains(key) {
                result.append(value)
            }
        }
        return result
    }
}
