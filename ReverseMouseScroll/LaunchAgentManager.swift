//
//  LaunchAgentManager.swift
//  ReverseMouseScroll
//
//  Created by Cyrus Zhang on 2026/1/14.
//

import Cocoa


struct LaunchAgentManager {
    // MARK: - Config
    private static let label = "com.local.reversemousescroll"
    private static let plistFileName = "\(label).plist"
    private static let installDirectoryName = "ReverseMouseScroll"
    private static let binaryName = "ReverseMouseScroll"

    // MARK: - Paths
    private static var launchAgentPlistURL: URL {
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
            .appendingPathComponent(plistFileName)
    }
    
    private static var appSupportDirURL: URL {
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent(installDirectoryName)
    }
    
    private static var installedBinaryURL: URL {
        return appSupportDirURL.appendingPathComponent(binaryName)
    }

    // MARK: - Public API
    static func installAndRun() {
        print("📦  Step 1: Installing application files...")
        
        // 1. 先复制文件 (不管有没有权限，先安家)
        do {
            try selfInstallBinary()
        } catch {
            print("❌  Copy failed: \(error)")
            exit(1)
        }
        print("✅  Binary installed to: \(installedBinaryURL.path)")

        // 2. 生成配置并写入
        ensureDirectory(at: launchAgentPlistURL.deletingLastPathComponent())
        let plist = makePlistDictionary(executablePath: installedBinaryURL.path)
        writePlist(plist)
        
        // 3. [核心修正] 引导用户给“新文件”授权
        print("\n🛡️  Step 2: Permission Setup (Important!)")
        print("---------------------------------------------------------------")
        print("👉  A Finder window will open revealing the INSTALLED file.")
        print("👉  Please drag the HIGHLIGHTED file into:")
        print("    System Settings -> Privacy & Security -> Accessibility")
        print("---------------------------------------------------------------")
        
        // 主动打开 Finder 并选中安装好的那个文件
        NSWorkspace.shared.activateFileViewerSelecting([installedBinaryURL])
        
        // 打开系统设置页面
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
        
        // 4. 询问用户是否已完成
        print("❓  Have you added the file? (Press Enter to continue)")
        _ = readLine() // 暂停，等待用户回车确认
        
        // 5. 加载服务
        print("🚀  Step 3: Starting background service...")
        
        launchctlLoad()

        print("✅  Installation Complete! The service is running.")
    }

    static func stopAndUninstall() {
        print("🗑️  Uninstalling...")
        launchctlUnload()
        try? FileManager.default.removeItem(at: launchAgentPlistURL)
        try? FileManager.default.removeItem(at: appSupportDirURL)
        print("✅  Uninstallation complete.")
    }

    static func status() -> String {
        if !FileManager.default.fileExists(atPath: launchAgentPlistURL.path) { return "Not Installed" }
        return isAgentRunning() ? "Running" : "Installed (Stopped)"
    }

    // MARK: - Internal Helpers
    private static func selfInstallBinary() throws {
        let fm = FileManager.default

        // 确保目标目录存在
        try fm.createDirectory(at: appSupportDirURL, withIntermediateDirectories: true)

        // 解析符号链接，确保拿到真实的可执行文件路径（brew 安装时 arguments[0] 是 symlink）
        let sourceURL = URL(fileURLWithPath: ProcessInfo.processInfo.arguments[0])
            .resolvingSymlinksInPath()

        // 如果当前已经在安装目录运行，就不复制了
        if sourceURL.standardizedFileURL == installedBinaryURL.standardizedFileURL { return }

        // 用 attributesOfItem（内部用 lstat）检测目标位置是否存在任何文件/符号链接
        // fileExists(atPath:) 会跟随符号链接，对「悬空符号链接」返回 false，导致无法清理旧文件
        if (try? fm.attributesOfItem(atPath: installedBinaryURL.path)) != nil {
            try fm.removeItem(at: installedBinaryURL)
        }

        try fm.copyItem(at: sourceURL, to: installedBinaryURL)
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: installedBinaryURL.path)
    }

    private static func ensureDirectory(at url: URL) {
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private static func makePlistDictionary(executablePath: String) -> [String: Any] {
        return [
            "Label": label,
            "ProgramArguments": [executablePath, "--daemon"],
            "RunAtLoad": true,
            "KeepAlive": true,
            "StandardOutPath": "/tmp/reversemousescroll.out",
            "StandardErrorPath": "/tmp/reversemousescroll.err"
        ]
    }

    private static func writePlist(_ plist: [String: Any]) {
        if let data = try? PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0) {
            try? data.write(to: launchAgentPlistURL)
        }
    }

    private static var guiTarget: String {
        return "gui/\(getuid())"
    }

    private static func launchctlLoad() {
        // 先 bootout 确保干净状态（忽略可能的报错）
        _ = runCommand("/bin/launchctl", args: ["bootout", guiTarget, launchAgentPlistURL.path])
        // 服务崩溃次数过多时 launchd 会将其标记为 disabled，此后 bootstrap 直接返回 error 5
        // 在 bootstrap 前显式 enable，确保崩溃保护不会阻止重新注册
        _ = runCommand("/bin/launchctl", args: ["enable", "\(guiTarget)/\(label)"])
        _ = runCommand("/bin/launchctl", args: ["bootstrap", guiTarget, launchAgentPlistURL.path])
    }

    private static func launchctlUnload() {
        _ = runCommand("/bin/launchctl", args: ["bootout", guiTarget, launchAgentPlistURL.path])
    }
    
    private static func isAgentRunning() -> Bool {
        let output = runCommand("/bin/launchctl", args: ["print", "\(guiTarget)/\(label)"])
        return output.contains("state = running")
    }
    
    private static func runCommand(_ launchPath: String, args: [String]) -> String {
        let task = Process()
        let pipe = Pipe()
        task.launchPath = launchPath
        task.arguments = args
        task.standardOutput = pipe
        task.standardError = Pipe()
        try? task.run()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
