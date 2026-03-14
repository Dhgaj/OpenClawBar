//
//  CoreModels.swift
//  
//  Purpose:
//      统一存放应用的基础数据模型、状态枚举与配置项
// 
//  Created by Dhgaj on 2026-03-12.
//  Modified by Dhgaj on 2026-03-14.
// 

import SwiftUI
import Combine
import Foundation

// MARK: - AppSettings (应用全局配置)

/// 应用全局设置（单例，通过 UserDefaults 持久化）
final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    /// 用户手动指定的 openclaw 可执行文件路径（空字符串表示自动检测）
    @Published var customOpenClawPath: String = UserDefaults.standard.string(forKey: "customOpenClawPath") ?? "" {
        didSet { UserDefaults.standard.set(customOpenClawPath, forKey: "customOpenClawPath") }
    }
    
    /// 状态轮询间隔（秒），默认 10 秒
    @Published var pollingInterval: Double = {
        let v = UserDefaults.standard.double(forKey: "pollingInterval")
        return v == 0 ? 10.0 : v
    }() {
        didSet { UserDefaults.standard.set(pollingInterval, forKey: "pollingInterval") }
    }
    
    /// 是否在操作成功/失败时发送系统通知（默认开启）
    @Published var notificationsEnabled: Bool = {
        if UserDefaults.standard.object(forKey: "notificationsEnabled") == nil { return true }
        return UserDefaults.standard.bool(forKey: "notificationsEnabled")
    }() {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }
    
    private init() {}
}

// MARK: - CommandResult (CLI 命令执行结果)

/// Shell 命令执行的完整结果
struct CommandResult {
    /// 命令退出码（0 表示成功）
    let exitCode: Int32
    /// 标准输出内容
    let stdout: String
    /// 标准错误输出内容
    let stderr: String
    /// 命令执行耗时（秒）
    let duration: TimeInterval
    
    /// 是否执行成功（退出码为 0）
    var isSuccess: Bool { exitCode == 0 }
    
    /// 综合输出（stdout 优先，否则取 stderr）
    var combinedOutput: String {
        let trimmed = stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? stderr : trimmed
    }
    
    var debugDescription: String {
        """
        [CommandResult]
          exitCode: \(exitCode)
          duration: \(String(format: "%.2f", duration))s
          stdout:   \(stdout.prefix(200))
          stderr:   \(stderr.prefix(200))
        """
    }
}

// MARK: - GatewayStatus (网关运行状态枚举)

/// OpenClaw Gateway 的运行状态
enum GatewayStatus: Equatable {
    case running
    case stopped
    case error(String)
    case unknown
    
    var displayText: String {
        switch self {
        case .running:         return "运行中"
        case .stopped:         return "已停止"
        case .error(let msg):  return "异常：\(msg)"
        case .unknown:         return "检测中"
        }
    }

    var menuBarEmoji: String { "🦞" }
    var shortText: String {
        switch self {
        case .running:  return "运行中"
        case .stopped:  return "已停止"
        case .error:    return "异常"
        case .unknown:  return "检测中"
        }
    }
    
    var menuBarIconName: String {
        switch self {
        case .running:  return "network"
        case .stopped:  return "network.slash"
        case .error:    return "exclamationmark.triangle"
        case .unknown:  return "ellipsis.circle"
        }
    }
    var coloredIconName: String {
        switch self {
        case .running, .stopped, .unknown: return "circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .running:  return .green
        case .stopped:  return .secondary
        case .error:    return .orange
        case .unknown:  return .secondary.opacity(0.5)
        }
    }
    
    var isRunning: Bool { if case .running = self { return true }; return false }
    var isError: Bool { if case .error = self { return true }; return false }
    var isStopped: Bool { if case .stopped = self { return true }; return false }
    
    var canStart: Bool {
        switch self {
        case .stopped, .error: return true
        default: return false
        }
    }
    var canStop: Bool { self == .running }
    
    static func == (lhs: GatewayStatus, rhs: GatewayStatus) -> Bool {
        switch (lhs, rhs) {
        case (.running, .running), (.stopped, .stopped), (.unknown, .unknown): return true
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}

// MARK: - LaunchAgentConfig (自启配置)

/// launchd Launch Agent 所需的配置字段
struct LaunchAgentConfig {
    let label: String
    let programPath: String
    let arguments: [String]
    let runAtLoad: Bool
    let keepAlive: Bool
    let stdoutPath: String?
    let stderrPath: String?
    let environmentVariables: [String: String]?
    
    static func openClawGateway(openClawPath: String) -> LaunchAgentConfig {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let logsDir = "\(homeDir)/.openclaw/logs"
        
        let extendedPath = [
            "/usr/local/bin",
            "/opt/homebrew/bin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin"
        ].joined(separator: ":")
        
        return LaunchAgentConfig(
            label: "ai.openclaw.gateway",
            programPath: openClawPath,
            arguments: ["gateway", "run"],
            runAtLoad: true,
            keepAlive: true,
            stdoutPath: "\(logsDir)/gateway.log",
            stderrPath: "\(logsDir)/gateway.err.log",
            environmentVariables: ["PATH": extendedPath]
        )
    }
    
    var plistFileName: String { "\(label).plist" }
    var plistFilePath: String {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(plistFileName)").path
    }
}

// MARK: - Double 扩展

private extension Double {
    func ifZero(default value: Double) -> Double {
        return self == 0 ? value : self
    }
}
