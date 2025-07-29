//
//  LaunchManage.swift
//  PandaHead
//
//  Created by ZhenShan Dong on 2021/6/18.
//  Copyright © 2021 HongYeGroup. All rights reserved.
//

import Foundation

public class LaunchManage:NSObject {
    
    private var userDefaultsKey:String = "LaunchManage_LaunchCount"
    
    @MainActor public static let shared = LaunchManage()
    
    /// 是否是第一次启动
    public var isFirstLaunch: Bool {
        return nowDayLaunchCount == 1;
    }
    
    /// 当天启动次数
    public var nowDayLaunchCount:NSInteger = 0
    /// 总启动天数
    public var launchDayCount:NSInteger = 0
    /// 总启动次数
    public var launchCount:NSInteger = 0
    
    private override init(){}
    /// 启动
    public func launch(){
        let nowDate = D_NowDate.dateFormatterString(.date)
        var arr = UserDefaults.standard.object(forKey: userDefaultsKey) as? [String] ?? []
        arr.append(nowDate)
        UserDefaults.standard.set(arr, forKey: userDefaultsKey)
        /// 当天启动次数
        self.nowDayLaunchCount = arr.filter({$0 == nowDate}).count
        // 总启动天数
        self.launchDayCount = arr.filterDuplicates({$0}).count
        // 总启动次数
        self.launchCount = arr.count;
        
    }
    
    
    
}
