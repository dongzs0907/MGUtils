//
//  DeviceUtils.swift
//  Trimmer
//
//  Created by 董振山 on 2023/7/7.
//  Copyright © 2023 trimmer. All rights reserved.
//
#if canImport(UIKit)
import UIKit


public final class DeviceUtils:NSObject {
    @MainActor public static let shared = DeviceUtils()

    /// 获取设备宽
    public var screenWidth:CGFloat {
        return UIScreen.main.bounds.width;
    };
    
    /// 获取设备高
    public var screenHeight:CGFloat{
        return UIScreen.main.bounds.height;
    };
    
    /// 状态栏高度
    public var statusBarHeight:CGFloat{
        if #available(iOS 13.0, *) {
            return UIApplication.shared.currentKeyWindow!.windowScene!.statusBarManager!.statusBarFrame.height
        } else {
           return UIApplication.shared.statusBarFrame.height
        };
    }
    
    /// 导航栏高度 44
    public var navBarHeight:CGFloat {
        return isIpad ? 50 : 44
    };

    /// tabbar 高度
    public var tabBarHeight:CGFloat{
        return isIpad ? (isIpadPro ? 65 : 50) : (isIphoneX ? 83 : 49);
    }

    /// 底部安全区高度
    public var bottomSafeAreaHeight:CGFloat{
        return isIphoneX ? 34 : 0;
    }
    
    
    /// 是否是iPad
    public var isIpad:Bool{
        return UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad ? true : false;
    }
    /// 是否是iPad Pro
    public var isIpadPro:Bool{
        return statusBarHeight <= 20 ? false : true
    }
    /// 是否是iPhoneX系列换手机
    public var isIphoneX:Bool{
        return statusBarHeight > 20 && isIpad == false ? true : false;
    }
    
    /// appstore 版本号
    public var appStoreVersion:String = ""
    
    /// 本地版本号
    public var localVersion:String = ""
    
    fileprivate var appId:String = "";
    
    private override init() {
        super.init()

    }
    
    /// 检查版本号是否超前
    /// - Parameters:
    ///   - appId: app id
    ///   - onResult: 返回是否超前
    public func checkVersion(appId: String, onResult: @escaping ((_ isPreRelease: Bool) -> ())) {
        self.appId = appId;
        Task {
            do {
                let version = try await self.fetchItunesAppVersion()
                    let itunesVersion = self.formatVersionString(version: version)
                    let localVersion = self.formatVersionString(version: self.getLocalAppVersion())
                    onResult(itunesVersion < localVersion)
            } catch {
                onResult(true);
            }
        }
    }

    
    
    func getLocalAppVersion() -> String {
        self.localVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String;
        return self.localVersion;
    }
    
    func fetchItunesAppVersion() async throws -> String {
        let url = URL(string: "https://itunes.apple.com/lookup?id=\(appId)")!
        
        // 3. 使用 URLSession 的 async 方法
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // 4. 在主线程外解析 JSON（避免阻塞主线程）
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]],
              let version = results.first?["version"] as? String
        else {
            throw VersionError.invalidResponse
        }
        
        // 5. 安全更新主线程属性
        self.appStoreVersion = version
        return version
    }

 
    func formatVersionString(version: String) -> Int {
        let digitsOnly = version.replacingOccurrences(of: ".", with: "")
        
        var formattedVersion = digitsOnly
        
        while formattedVersion.count < 4 {
            formattedVersion += "0"
        }
        
        return formattedVersion.int()
    }
    
    enum VersionError: Error {
        case invalidResponse
    }
}


extension UIApplication {
    public var currentKeyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .first(where: { $0 is UIWindowScene })
                .flatMap { $0 as? UIWindowScene }?
                .windows
                .first(where: \.isKeyWindow)
        } else {
            return keyWindow
        }
    }
}

#endif
