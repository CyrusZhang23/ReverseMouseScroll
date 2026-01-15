//
//  EventTapHandler.swift
//  ReverseMouseScroll
//
//  Created by Cyrus Zhang on 2026/1/13.
//

import Cocoa
import CoreGraphics

// ==========================================
// MARK: - Global State
// ==========================================

// 全局引用，防止被释放
var runLoopSource: CFRunLoopSource?
var eventTap: CFMachPort?

// 用于保存休眠唤醒的观察者对象
var wakeObserver: NSObjectProtocol?

// ==========================================
// MARK: - 1. Core Logic (业务逻辑层)
// ==========================================

/// 处理具体的滚动事件反转逻辑
/// - Parameter event: 传入的原始事件
/// - Returns: 处理后的事件（或者 nil 表示丢弃）
private func processScrollEvent(_ event: CGEvent) -> CGEvent? {
    // 判断滚动事件来源
    // 0 = 物理鼠标滚轮 (我们要处理的)
    // 1 = 触控板 / Magic Mouse (保持原样)
    let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous)
    
    // 如果是触控板（连续滚动），直接返回原事件
    if isContinuous != 0 {
        return event
    }
    
    // 获取最新配置 (支持命令行热更新)
    let config = ConfigManager.shared.getConfig()
    
    if config.reverseY {
        let dy = event.getDoubleValueField(.scrollWheelEventDeltaAxis1)
        event.setDoubleValueField(.scrollWheelEventDeltaAxis1, value: -dy)
    }
    
    if config.reverseX {
        let dx = event.getDoubleValueField(.scrollWheelEventDeltaAxis2)
        event.setDoubleValueField(.scrollWheelEventDeltaAxis2, value: -dx)
    }
    
    return event
}


// ==========================================
// MARK: - 2. C-Style Callback (接口层)
// ==========================================

/// 符合 CGEventTapCallBack 签名的回调函数
func eventTapCallback(proxy: CGEventTapProxy,
                      type: CGEventType,
                      event: CGEvent,
                      refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    
    // 1. [关键] 处理超时自动禁用机制 (System Guard)
    // 如果系统负载过高导致回调处理太慢，系统会自动禁用 Tap，这里必须手动由程序重新启用
    if type == .tapDisabledByTimeout {
        
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return nil
    }
    
    // 2. 再次确认事件类型
    guard type == .scrollWheel else {
        return Unmanaged.passRetained(event)
    }
    
    // 3. 调用业务逻辑
    if let processedEvent = processScrollEvent(event) {
        return Unmanaged.passRetained(processedEvent)
    } else {
        return nil
    }
}


// ==========================================
// MARK: - 3. Setup (配置与生命周期)
// ==========================================

func startEventTap() {
    // 防止重复启动
    if eventTap != nil { return }
    
    
    
    let mask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)
    
    // 1. 创建 Event Tap
    guard let newEventTap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: mask,
        callback: eventTapCallback,
        userInfo: nil
    ) else {
        print("❌ Failed to create event tap. Check Permissions!")
        
        return
    }

    eventTap = newEventTap
    
    // 2. 添加到 RunLoop
    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, newEventTap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
    
    // 3. 启用
    CGEvent.tapEnable(tap: newEventTap, enable: true)
    
    
    // 4. 注册系统唤醒监听
    // 确保之前没有注册过，防止重复添加
    if wakeObserver == nil {
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: nil
        ) { _ in
            
            // 唤醒后，先停止旧的，再重新创建新的连接
            stopEventTap()
            // 稍微延迟一点点启动，给系统驱动一点反应时间（可选，但直接调用通常也没问题）
            startEventTap()
        }
    }
}

func stopEventTap() {
    // 1. 停止并清理 Tap
    if let tap = eventTap, let source = runLoopSource {
        CGEvent.tapEnable(tap: tap, enable: false)
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        
        eventTap = nil
        runLoopSource = nil
        
    }
    
    // 2. [新增] 清理系统唤醒监听
    // 注意：如果是唤醒时的重置操作，startEventTap 会再次把这个 observer 加回来
    if let observer = wakeObserver {
        NSWorkspace.shared.notificationCenter.removeObserver(observer)
        wakeObserver = nil
    }
}
