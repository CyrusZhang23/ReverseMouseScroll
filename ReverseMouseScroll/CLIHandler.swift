//
//  CLIHandler.swift
//  ReverseMouseScroll
//
//  Created by Cyrus Zhang on 2026/1/14.
//

import Foundation

class CLIHandler {

    static func processArguments() {
        let args = Array(CommandLine.arguments.dropFirst())

        if args.isEmpty {
            printUsage()
            exit(0)
        }

        switch args[0] {
        case "--install":
            LaunchAgentManager.installAndRun()
            exit(0)
            
        case "--uninstall":
            LaunchAgentManager.stopAndUninstall()
            exit(0)
            
        case "--status":
            print("Status: \(LaunchAgentManager.status())")
            exit(0)
            
        case "--show":
            let config = ConfigManager.shared.getConfig()
            print("X-Axis: \(config.reverseX ? "Reverse 🔄" : "Normal ➡️")")
            print("Y-Axis: \(config.reverseY ? "Reverse 🔄" : "Normal ⬇️")")
            exit(0)
            
        case "--setreverse":
            handleSetReverse(args: Array(args.dropFirst()))
            exit(0)
            
        // 仅供 launchd 调用
        case "--daemon":
            print("🚀 Daemon started...")
            // 1. 尝试启动 (即使失败也不退出)
            startEventTap()
            // 2. [死锁] 保证进程不退出，防止 launchd 重启循环
            CFRunLoopRun()
            exit(0)
            
        case "--run":
            print("🔧 Debug Mode (Press Ctrl+C to stop)")
            startEventTap()
            CFRunLoopRun()
            
        default:
            print("❌ Unknown command: \(args[0])")
            printUsage()
            exit(1)
        }
    }
    
    static func handleSetReverse(args: [String]) {
        var i = 0
        while i < args.count {
            let currentArg = args[i].lowercased()
            if (currentArg == "x" || currentArg == "y") && i + 1 < args.count {
                let mode = args[i+1].lowercased()
                if mode == "normal" || mode == "reverse" {
                    ConfigManager.shared.setReverse(axis: currentArg, mode: mode)
                    i += 2
                } else {
                    print("❌ Error: Invalid mode '\(mode)'. Use 'normal' or 'reverse'.")
                    return
                }
            } else {
                i += 1
            }
        }
    }

    static func printUsage() {
        print("""
        Usage:
            --install       Install & Start (requires permission)
            --uninstall     Stop & Clean up
            --status        Check status
            --show          Show current config
            --setreverse    Set direction (e.g. 'x reverse y normal')
            --run           Debug mode
        """)
    }
}
