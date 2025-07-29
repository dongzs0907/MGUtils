//
//  UIViewController(extension).swift
//  YYHRManagement
//
//  Created by ZhenShan Dong on 2020/7/30.
//  Copyright © 2020 ZhenShanDong. All rights reserved.
//
#if canImport(UIKit)
import Foundation
import UIKit


extension UIViewController{
    
    /// celerity present
    @objc public func present(_ viewController:UIViewController){
        viewController.modalPresentationStyle = .fullScreen;
        self.present(viewController, animated: true, completion: nil)
    }
    
    /// celerity pop
    @objc public func dismiss(){
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc public func push(_ viewController:UIViewController){
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    @objc public func pop(){
        self.navigationController?.popViewController(animated: true)
    }
    
    public class func initStoryboard(_ storyboard:String) -> UIViewController{
        return UIStoryboard(name: storyboard, bundle: Bundle.main).instantiateViewController(withIdentifier: NSStringFromClass(self).components(separatedBy: ".").last!)
    }
    
    @objc public func commonBackAction(){
        if self.isKind(of: UINavigationController.self) {
            (self as! UINavigationController).popViewController(animated: true)
        }else{
            self.navigationController?.popViewController(animated: true)
        }
    }
    
}
#endif
