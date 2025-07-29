//
//  UITableView(extension).swift
//  SwiftCommon
//
//  Created by 董振山 on 2018/7/3.
//  Copyright © 2018年 董振山. All rights reserved.
//
#if canImport(UIKit)
import Foundation
import UIKit

extension UITableView{
    /** 获取最后一个section */
    public var lastSection:Int{
        return numberOfSections > 0 ? numberOfSections - 1 : 0
    }
    /** 获取指定分区的最后一个cell的下标 */
    public func lastForIndexPath(section:Int=0) -> IndexPath{
        return IndexPath.init(row: self.numberOfRows(inSection: section) - 1, section: section)
    }
    
    /** 移除footerView */
    public func removeTableFooterView() {
        tableFooterView = nil
    }
    
    /** 移除headerView */
    public func removeTableHeaderView() {
        tableHeaderView = nil
    }
    /** 更新HeaderView */
    public func updateTableHeaderView<T:UIView>(_ view:T){
        self.removeTableHeaderView()
        self.tableHeaderView = view
    }
    /** 更新footerView */
    public func updateTableFooterView<T:UIView>(_ view:T){
        self.removeTableFooterView()
        self.tableFooterView = view
    }
    
    /** 刷新完成后 执行操作 */
    public func reloadData(_ completion:@escaping () -> Void){
        UIView.animate(withDuration: 0, animations: {
            self.reloadData()
        }, completion: { (_) in
            completion()
        })
    }
    
    /** 注册class Cell */
    public func register<T:UITableViewCell>(CellWithClass name: T.Type){
        register(T.self, forCellReuseIdentifier: String.init(describing: name))
    }
    
    /** 注册Nib cell */
    public func registerNib<T:UITableViewCell>(CellWithNib name: T.Type){
        register(UINib.init(nibName: String.init(describing: name), bundle: Bundle.main), forCellReuseIdentifier: String.init(describing: name))
    }
    
    /** 创建Cell */
    public func dequeueReusableCell<T:UITableViewCell>(className: T.Type, for indexPath: IndexPath) -> T{
        return dequeueReusableCell(withIdentifier: String(describing: className), for: indexPath) as! T
    }
    
    
}
#endif
