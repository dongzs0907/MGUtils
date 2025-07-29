//
//  IB_UIKit.swift
//  SwiftCommon
//
//  Created by 董振山 on 2018/7/10.
//  Copyright © 2018年 董振山. All rights reserved.
//
#if canImport(UIKit)
import Foundation
import UIKit
extension UILabel{
    
    @IBInspectable public var tr:String {
        get{
            return self.text ?? "" ;
        }
        set{
            self.text = NSLocalizedString(newValue, comment: "")
        }
    }
    
    @IBInspectable public var ipadFontSize:CGFloat{
        get{
            return self.ipadFontSize
        }
        set{
            self.font = UIFont.init(name: self.font.fontName, size: DeviceUtils.shared.isIpad ? newValue : self.font.pointSize)
        }
    }
    
    
}

extension UIButton{
    
    @IBInspectable public var tr:String {
        get{
            return self.titleLabel?.text ?? "";
        }
        set{
            self.setTitle(NSLocalizedString(newValue, comment: ""), for: UIControl.State.normal)
        }
    }
    
    @IBInspectable public var ipadFontSize:CGFloat{
        get{
            return self.ipadFontSize
        }
        set{
            self.titleLabel?.font = UIFont.init(name: self.titleLabel!.font.fontName, size: DeviceUtils.shared.isIpad ? newValue : self.titleLabel!.font.pointSize)
        }
    }
    
    
}


extension UITextField{
    @IBInspectable public var ipadFontSize:CGFloat{
        get{
            return self.ipadFontSize
        }
        set{
            self.font = UIFont.init(name: self.font!.fontName, size: DeviceUtils.shared.isIpad ? newValue : self.font!.pointSize)
        }
    }
}


extension UITextView{
    @IBInspectable public var ipadFontSize:CGFloat{
        get{
            return self.ipadFontSize
        }
        set{
            self.font = UIFont.init(name: self.font!.fontName, size: DeviceUtils.shared.isIpad ? newValue : self.font!.pointSize)
        }
    }
}

extension NSLayoutConstraint{
    @IBInspectable public var ipadConstraint:CGFloat{
        get{
            return self.ipadConstraint
        }
        set{
            self.constant = DeviceUtils.shared.isIpad ? newValue : self.constant;
        }
    }
    @IBInspectable public var ipadMultiple:CGFloat{
        get{
            return self.ipadMultiple
        }
        set{
            self.constant = DeviceUtils.shared.isIpad ? newValue * self.constant : self.constant;
        }
    }
}
#endif
