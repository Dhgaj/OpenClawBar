//
//  CoreUtilities.swift
//  
//  Purpose:
//      系统底层的统一工具类库
// 
//  Created by Dhgaj on 2026-03-12.
//  Modified by Dhgaj on 2026-03-14.
// 

import Foundation
import OSLog
import UserNotifications

// MARK: - AppLogger (统一日志输出)

/// 统一日志工具，基于 OSLog 实现
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.openclaw.bar"
    
    private static let general = Logger(subsystem: subsystem, category: "General")
    static let gateway  = Logger(subsystem: subsystem, category: "Gateway")
    static let service  = Logger(subsystem: subsystem, category: "Service")
    static let shell    = Logger(subsystem: subsystem, category: "Shell")
    static let ui       = Logger(subsystem: subsystem, category: "UI")
    
    static func debug(_ message: String)  { general.debug("\(message, privacy: .public)") }
    static func info(_ message: String)   { general.info("\(message, privacy: .public)") }
    static func warning(_ message: String){ general.warning("\(message, privacy: .public)") }
    static func error(_ message: String)  { general.error("\(message, privacy: .public)") }
}

// MARK: - NotificationHelper (系统通知发送工具)

/// macOS 系统通知发送工具
enum NotificationHelper {
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error { AppLogger.error("通知权限申请失败：\(error.localizedDescription)") }
            AppLogger.info("通知权限：\(granted ? "已授权" : "被拒绝")")
        }
    }
    
    static func send(title: String, body: String, identifier: String = UUID().uuidString) {
        guard AppSettings.shared.notificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error { AppLogger.error("发送通知失败：\(error.localizedDescription)") }
        }
    }
    
    static func notifyGatewayStarted() { send(title: "🦞 OpenClaw", body: "Gateway 已成功启动", identifier: "gateway.started") }
    static func notifyGatewayStopped() { send(title: "🦞 OpenClaw", body: "Gateway 已停止", identifier: "gateway.stopped") }
    static func notifyError(message: String) { send(title: "⚠️ OpenClawBar 错误", body: message, identifier: "error") }
}

// MARK: - PlistWriter (launchd plist 读写)

/// launchd plist 文件的读写工具
enum PlistWriter {
    static func write(_ config: LaunchAgentConfig) throws {
        let dir = (config.plistFilePath as NSString).deletingLastPathComponent
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
        let content = generateXML(from: config)
        try content.write(toFile: config.plistFilePath, atomically: true, encoding: .utf8)
    }
    
    static func remove(config: LaunchAgentConfig) throws {
        let path = config.plistFilePath
        if FileManager.default.fileExists(atPath: path) { try FileManager.default.removeItem(atPath: path) }
    }
    
    static func exists(config: LaunchAgentConfig) -> Bool { FileManager.default.fileExists(atPath: config.plistFilePath) }
    
    private static func generateXML(from config: LaunchAgentConfig) -> String {
        let allArgs = ([config.programPath] + config.arguments)
            .map { "    <string>\($0)</string>" }.joined(separator: "\n")
        
        let stdoutBlock = config.stdoutPath.map { "  <key>StandardOutPath</key>\n  <string>\($0)</string>" } ?? ""
        let stderrBlock = config.stderrPath.map { "  <key>StandardErrorPath</key>\n  <string>\($0)</string>" } ?? ""
        
        var envBlock = ""
        if let envs = config.environmentVariables, !envs.isEmpty {
            let dictContent = envs.map { "      <key>\($0.key)</key>\n      <string>\($0.value)</string>" }.joined(separator: "\n")
            envBlock = "  <key>EnvironmentVariables</key>\n  <dict>\n\(dictContent)\n  </dict>"
        }
        
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>\(config.label)</string>
          <key>ProgramArguments</key>
          <array>\n\(allArgs)\n  </array>
          <key>RunAtLoad</key>
          <\(config.runAtLoad ? "true" : "false")/>
          <key>KeepAlive</key>
          <\(config.keepAlive ? "true" : "false")/>
        \(envBlock)\n\(stdoutBlock)\n\(stderrBlock)
        </dict>
        </plist>
        """
    }
}

// MARK: - ShellRunner (进程调用工具)

/// 静默执行 Shell 命令的底层工具类
enum ShellRunner {
    static func run(command: String, arguments: [String] = [], environment: [String: String]? = nil, timeout: TimeInterval = 15) async throws -> CommandResult {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = runSync(command: command, arguments: arguments, environment: environment, timeout: timeout)
                switch result {
                case .success(let cmd): continuation.resume(returning: cmd)
                case .failure(let err): continuation.resume(throwing: err)
                }
            }
        }
    }

    private static func runSync(command: String, arguments: [String], environment: [String: String]?, timeout: TimeInterval) -> Result<CommandResult, ShellRunnerError> {
        let shellCommand = buildShellCommand(command: command, arguments: arguments)
        AppLogger.shell.debug("执行命令：/bin/sh -c \"\(shellCommand)\"")

        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", shellCommand]
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        var env = ProcessInfo.processInfo.environment
        let extraPaths = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        env["PATH"] = extraPaths + ":" + (env["PATH"] ?? "")
        if let extraEnv = environment { env.merge(extraEnv) { _, new in new } }
        process.environment = env

        let startTime = Date()
        do { try process.run() } catch { return .failure(.launchFailed(error.localizedDescription)) }

        let timeoutWork = DispatchWorkItem { if process.isRunning { process.terminate() } }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: timeoutWork)

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        timeoutWork.cancel()

        let duration = Date().timeIntervalSince(startTime)
        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""

        if process.terminationReason == .uncaughtSignal { return .failure(.timeout(timeout)) }

        return .success(CommandResult(exitCode: process.terminationStatus, stdout: stdout, stderr: stderr, duration: duration))
    }

    private static func buildShellCommand(command: String, arguments: [String]) -> String {
        let escapedCmd = shellEscape(command)
        let escapedArgs = arguments.map { shellEscape($0) }
        return ([escapedCmd] + escapedArgs).joined(separator: " ")
    }

    private static func shellEscape(_ str: String) -> String {
        let safeChars = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "/-_.=:@"))
        if str.unicodeScalars.allSatisfy({ safeChars.contains($0) }) && !str.isEmpty { return str }
        let escaped = str.replacingOccurrences(of: "'", with: "'\\''")
        return "'\(escaped)'"
    }
}

enum ShellRunnerError: Error, LocalizedError {
    case executableNotFound(String)
    case launchFailed(String)
    case timeout(TimeInterval)

    var errorDescription: String? {
        switch self {
        case .executableNotFound(let path): return "找不到可执行文件：\(path)"
        case .launchFailed(let reason):     return "命令启动失败：\(reason)"
        case .timeout(let seconds):         return "命令执行超时（超过 \(Int(seconds)) 秒）"
        }
    }
}
