//
//  UIButton+ImageTitleSpacing.swift
//  MG_Utils
//
//  Created by 董振山 on 2023/8/3.
//
#if canImport(UIKit)
import Foundation
import UIKit

public enum ButtonEdgeInsetsStyle{
    case top
    case left
    case right
    case bottom
}

extension UIButton{
    
    /// 按钮文字与图片排版
    /// - Parameters:
    ///   - style: 图片想要在的位置
    ///   - space: 间距
    public func layoutButtonWithEdgeInsetsStyle(style:ButtonEdgeInsetsStyle, space:CGFloat){
        let imageWidth = self.imageView?.frame.size.width ?? 0;
        let imageHeight = self.imageView?.frame.size.height ?? 0;
        let labelWidth = self.titleLabel?.intrinsicContentSize.width ?? 0;
        let labelHeight = self.titleLabel?.intrinsicContentSize.height ?? 0;
        var imageEdgeInsets = UIEdgeInsets.zero
        var labelEdgeInsets = UIEdgeInsets.zero
        switch (style){
        case .top:
            imageEdgeInsets = UIEdgeInsets.init(top: -labelHeight - space / 2.0, left: (self.frame.size.width - imageWidth) / 2.0, bottom: 0, right: (self.frame.size.width - imageWidth) / 2.0)
            labelEdgeInsets = UIEdgeInsets.init(top:0, left: -imageWidth, bottom:-imageHeight-space/2.0, right: 0);
            break;
        case .left:
            imageEdgeInsets = UIEdgeInsets.init(top:0,left: -space/2.0,bottom: 0,right: space/2.0);
            labelEdgeInsets = UIEdgeInsets.init(top: 0,left: space/2.0,bottom: 0, right: -space/2.0);
            break
        case .right:
            imageEdgeInsets = UIEdgeInsets.init(top:0,left: labelWidth+space/2.0,bottom: 0,right: -labelWidth-space/2.0);
            labelEdgeInsets = UIEdgeInsets.init(top:0,left: -imageWidth-space/2.0,bottom: 0, right:imageWidth+space/2.0);
            break
        case .bottom:
            imageEdgeInsets = UIEdgeInsets.init(top:0,left: 0,bottom: -labelHeight-space/2.0,right: -labelWidth);
            labelEdgeInsets = UIEdgeInsets.init(top:-imageHeight-space/2.0,left: -imageWidth,bottom: 0,right: 0);
            break
        }
        
        self.titleEdgeInsets = labelEdgeInsets;
        self.imageEdgeInsets = imageEdgeInsets;
    }
}
#endif
