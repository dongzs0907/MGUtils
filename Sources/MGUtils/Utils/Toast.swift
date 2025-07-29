//
//  Toast.swift
//  YYCircle_CN
//
//  Created by ZhenShan Dong on 2022/4/11.
//
#if canImport(UIKit)
import Foundation
import UIKit

public class Toast:MBProgressHUD{
    
    public static let afterDelay:Float = 2
    
    public static let keyWindow:UIWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first!
    
    
    /// 显示错误提示toast
    /// - Parameters:
    ///   - error: 错误信息
    ///   - toView: 将要展示于哪个视图
    public class func showError(_ error:String, _ toView:UIView = keyWindow){
        self.showCustomIcon(iconName: "app_close_line", title: error, toView: toView)
    }
    
    /// 显示成功提示toast
    /// - Parameters:
    ///   - success: 将要显示的文本
    ///   - toView: 将要展示于哪个视图
    public class func showSuccess(_ success:String, _ toView:UIView = keyWindow){
        self.showCustomIcon(iconName: "app_check_line", title: success, toView: toView)
    }
    
    
    /// 显示加载toast
    /// - Parameters:
    ///   - message: 文本
    ///   - toView: 将要展示于哪个视图
    public class func showLoading(_ message:String="Loading...", _ toView:UIView = keyWindow){
        _ = self.createMessage(message: message, toView: toView)
    }
    
    
    /// 显示自动消失toast
    /// - Parameters:
    ///   - message: 文本
    ///   - delayTime: 展示时长
    ///   - toView: 将要展示于哪个视图
    public class func showAutoHideMsg(_ message:String, delayTime:Float=afterDelay,toView:UIView = keyWindow){
        self.createAutoHideCustomHUD1(message: message, toView: toView, remainTime: delayTime, mode: .text)
    }
    
    
    /// 隐藏toast
    /// - Parameter view: 将要移除视图上的toast
    public class func hide(view:UIView=keyWindow){
        do{
            if (Thread.isMainThread){
                MBProgressHUD.hideHUDForView(view, animated: true)
            }else{
                DispatchQueue.main.async {
                    MBProgressHUD.hideHUDForView(view, animated: true)
                }
            }
            
        }
    }
    
    
    
    fileprivate class func showCustomIcon(iconName:String,title:String,toView:UIView = keyWindow){
        
        let hud = MBProgressHUD.showHUDAddedTo(toView, animated: true)
        hud.detailsLabel.text = title;
        hud.customView = UIImageView.init(image: .init(named: iconName))
        hud.mode = .customView;
        hud.detailsLabel.font = hud.label.font;
        hud.removeFromSuperViewOnHide = true;
        if toView.superview == nil && toView.isKind(of: UIWindow.self) != true{
            hud.offset.y = -64;
        }
        hud.hide(animated: true, afterDelay: TimeInterval(afterDelay))
    }
    
    
    
    fileprivate class func createMessage(message:String,toView:UIView = keyWindow) -> MBProgressHUD{
        let hud = MBProgressHUD.showHUDAddedTo(toView, animated: true)
        hud.detailsLabel.text = message
        hud.detailsLabel.font = hud.label.font;
        hud.removeFromSuperViewOnHide = true;
//        hud.dimBackground = false;
        if toView.superview == nil && toView.isKind(of: UIWindow.self) != true{
            hud.offset.y = -64;
        }
        return hud
    }
    
    fileprivate class func createAutoHideCustomHUD1(message:String,toView:UIView=keyWindow, remainTime:Float=afterDelay, mode:MBProgressHUDMode = .text){
        let hud = MBProgressHUD.showHUDAddedTo(toView, animated: true)
        hud.detailsLabel.text = message
        hud.detailsLabel.font = hud.label.font;
        hud.mode = mode;
        hud.removeFromSuperViewOnHide = true;
//        hud.dimBackground = false;
        if toView.superview == nil && toView.isKind(of: UIWindow.self) != true{
            hud.offset.y = -64;
        }
        hud.hide(animated:true, afterDelay: TimeInterval(remainTime))
    }
    
    
}
#endif
