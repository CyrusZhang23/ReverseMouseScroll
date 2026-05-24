// ScrollConfig.swift
import Foundation


struct ScrollConfig {
    var reverseX: Bool
    var reverseY: Bool
}

// 定义存储的 Key (类似于寄存器地址)
private let kReverseXKey = "com.local.reversemousescroll.x"
private let kReverseYKey = "com.local.reversemousescroll.y"

class ConfigManager {
    static let shared = ConfigManager()
    
    // 获取当前配置 (读寄存器)
    func getConfig() -> ScrollConfig {
        // 默认策略：如果没有设置过，默认 X 不反转，Y 反转
        let rx = UserDefaults.standard.object(forKey: kReverseXKey) as? Bool ?? false
        let ry = UserDefaults.standard.object(forKey: kReverseYKey) as? Bool ?? true
        
        return ScrollConfig(reverseX: rx, reverseY: ry)
    }
    
    // 更新配置 (写寄存器)
    func setReverse(axis: String, mode: String) {
        let isReverse = (mode.lowercased() == "reverse")
        let key = (axis.lowercased() == "x") ? kReverseXKey : kReverseYKey
        
        
        // 写入磁盘，后台进程下次读取时即可获取最新值
        UserDefaults.standard.set(isReverse, forKey: key)
        // [修改] 同时保留 print (给用户看) 和 Logger (给系统看)
        let logMsg = "Configuration changed: \(axis.uppercased()) -> \(mode.capitalized)"
        print("✅ \(logMsg)")
        
    }
}
