//
//  Date(extension).swift
//  SwiftCommon
//
//  Created by 董振山 on 2018/7/2.
//  Copyright © 2018年 董振山. All rights reserved.
//
#if canImport(UIKit)
import Foundation

/// 获取当前时间的时间戳
public var D_NowDate:String{
    return "\(Date.init().timeIntervalSince1970.int)"
}

public enum DateFormatterType{
    /// 日期 yyyy-MM-dd
    case date
    /// 时间 HH:mm:ss
    case time
    /// 完整格式 yyyy-MM-dd HH:mm:ss
    case allDate
    /// 自定义格式 “”
    case custom(String)
}

extension String{
    /// 时间戳 格式化
    public func dateFormatterString(_ type:DateFormatterType) -> String {
        var formatStr = ""
        switch type {
        case .date:
            formatStr = "yyyy-MM-dd"
            break;
        case .time:
            formatStr = "HH:mm:ss"
            break;
        case .allDate:
            formatStr = "yyyy-MM-dd HH:mm:ss"
            break;
        case .custom(let str):
            formatStr = str
            break
        }
        //转换为时间
        let timeInterval:TimeInterval = TimeInterval(self)!
        let date = NSDate(timeIntervalSince1970: timeInterval)
        //格式化输出
        let dformatter = DateFormatter()
        dformatter.dateFormat = formatStr
        return dformatter.string(from: date as Date)
    }
    
    
    /// 时间转换为时间戳  yyyy-MM-dd HH:mm:ss
    public func stringToTimeStamp(format:String) -> String {
        let dfmatter = DateFormatter()
        dfmatter.dateFormat = format
        let date = dfmatter.date(from: self)
        let dateStamp:TimeInterval = date!.timeIntervalSince1970
        let dateSt:Int = Int(dateStamp)
        return String(dateSt)
    }
    
    public func stringToDate(format:String) -> Date{
        let formatter = DateFormatter.init()
        formatter.dateFormat = format;
        let date = formatter.date(from: self)
        return date!
    }
    
    public func stringToStamp(format:String) -> Int{
        let date = self.stringToDate(format: format)
        return Int(date.timeIntervalSince1970)
    }

}

extension Date{
    
    /// dates序列化为字符串
    /// - Parameter format: 格式
    public func timeStampToString(format:String) -> String{
        let formatter = DateFormatter.init()
        formatter.dateFormat = format
        let dateStr = formatter.string(from: self)
        return dateStr
    }
}
#endif
