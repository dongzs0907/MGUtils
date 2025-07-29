//
//  Number(extension).swift
//  Swift-Common
//
//  Created by 董振山 on 2018/4/17.
//  Copyright © 2018年 董振山. All rights reserved.
//

#if canImport(UIKit)
import UIKit

extension Float{
    public var int:Int{
        return Int(self)
    }
    public var double:Double{
        return Double(self)
    }
    public var cgFloat:CGFloat{
        return CGFloat(self)
    }
}
extension Double{
    public var int:Int{
        return Int(self)
    }
    public var float:Float{
        return Float(self)
    }
    public var cgFloat:CGFloat{
        return CGFloat(self)
    }
    @MainActor
    public var auto:CGFloat{
        return Adaptive(self.cgFloat);
    }
}
extension Int{
    public var float:Float{
        return Float(self)
    }
    public var double:Double{
        return Double(self)
    }
    public var cgFloat:CGFloat{
        return CGFloat(self)
    }
    @MainActor
    public var auto:CGFloat{
        return Adaptive(self.cgFloat);
    }
}
extension CGFloat{
    public var int:Int{
        return Int(self)
    }
    public var double:Double{
        return Double(self)
    }
    public var float:Float{
        return Float(self)
    }
    @MainActor
    public var auto:CGFloat{
        return Adaptive(self);
    }
}

@MainActor
func Adaptive(_ num:CGFloat) -> CGFloat{
    if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
        return num / 768 * [UIScreen.main.bounds.width,UIScreen.main.bounds.height].min()!;
    }
    return num / 375 * [UIScreen.main.bounds.width,UIScreen.main.bounds.height].min()!;
}
#endif
