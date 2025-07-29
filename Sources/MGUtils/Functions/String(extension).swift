//
//  String(extension).swift
//  YYHRManagement
//
//  Created by ZhenShan Dong on 2020/7/30.
//  Copyright © 2020 ZhenShanDong. All rights reserved.
//

import Foundation

public extension String{
    /// 截取index之后的字符串(包含index)
    func mg_subString(from index: Int) -> String{
        if self.count > index {
            let startIndex = self.index(self.startIndex, offsetBy: index)
            let substring = self[startIndex..<self.endIndex]
            return String(substring)
        } else {
            return self
        }
    }
    /// 截取index之前的字符串（不包含index）
    func mg_subString(to index: Int) -> String{
        if self.count > index {
            let endIndex = self.index(self.startIndex, offsetBy: index)
            let substring = self[self.startIndex..<endIndex]
            return String(substring)
        } else {
            return self
        }
    }
    
    /// 截取范围内的字符串(左右都包含)
    func mg_substring(from index1: Int , to index2: Int) -> String{
        if self.count > index1 && self.count > index2 {
            let startIndex = self.index(self.startIndex, offsetBy: index1)
            let endIndex = self.index(self.startIndex, offsetBy: index2)
            let substring = self[startIndex...endIndex]
            return String(substring)
        } else {
            return self
        }
    }
    
    
    
    func double() -> Double{
        return Double(self) == nil ? 0.0 : Double(self)!
    }
    func int() -> Int{
        return self.double().int
    }
    func float() -> Float{
        return self.double().float
    }
    
    /// 本地化
    var tr:String{
        return NSLocalizedString(self, comment: "");
    }
    
//    func tr() -> String{
//        return NSLocalizedString(self, comment: self);
//    }
    
}
