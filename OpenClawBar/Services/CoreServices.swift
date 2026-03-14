//
//  CoreServices.swift
//  
//  Purpose:
//      统一收纳所有业务逻辑与外围系统交互的服务类
// 
//  Created by Dhgaj on 2026-03-12.
//  Modified by Dhgaj on 2026-03-14.
// 

import Foundation
import OSLog
import Combine

// MARK: - 1. GatewayService (网关核心控制服务)

/// Gateway 控制服务：封装所有 openclaw gateway 相关命令
final class GatewayService {
    private let openClawPath: String
    private let launchAgentService: LaunchAgentService
    
    init(openClawPath: String) {
        self.openClawPath = openClawPath
        self.launchAgentService = LaunchAgentService(openClawPath: openClawPath)
    }
    
    func getStatus() async -> GatewayStatus {
        AppLogger.gateway.info("检测 Gateway 状态...")
        do {
            let result = try await ShellRunner.run(command: openClawPath, arguments: ["health"], timeout: 8)
            return parseHealthOutput(result)
        } catch {
            AppLogger.gateway.error("状态检测失败：\(error.localizedDescription)")
            return .error(error.localizedDescription)
        }
    }
    
    private func parseHealthOutput(_ result: CommandResult) -> GatewayStatus {
        if result.isSuccess {
            AppLogger.gateway.info("Gateway 运行正常")
            return .running
        }

        let combinedLower = result.combinedOutput.lowercased()
        let stderrLower   = result.stderr.lowercased()

        let stoppedKeywords = [
            "not running", "econnrefused", "connection refused", "enoent",
            "gateway is not", "gateway closed", "abnormal closure",
            "failed to start cli", "not loaded", "start with:"
        ]
        
        if stoppedKeywords.contains(where: { combinedLower.contains($0) }) {
            AppLogger.gateway.info("Gateway 未运行")
            return .stopped
        }

        let isOnlyPluginWarning = combinedLower.contains("[plugins]") && !stoppedKeywords.contains(where: { combinedLower.contains($0) })
        if isOnlyPluginWarning {
            AppLogger.gateway.info("Gateway 运行正常（忽略 plugin 警告）")
            return .running
        }

        let errorMsg = stderrLower.isEmpty ? result.stdout : result.stderr
        AppLogger.gateway.warning("Gateway 状态异常：\(result.combinedOutput)")
        return .error(errorMsg.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    @discardableResult
    func start() async throws -> CommandResult {
        AppLogger.gateway.info("尝试修复并启动 Gateway...")
        try? launchAgentService.ensureLoaded()
        let result = try await ShellRunner.run(command: openClawPath, arguments: ["gateway", "start"], timeout: 20)
        AppLogger.gateway.info("启动结果：exitCode=\(result.exitCode)")
        return result
    }
    
    @discardableResult
    func stop() async throws -> CommandResult {
        AppLogger.gateway.info("停止 Gateway...")
        let result = try await ShellRunner.run(command: openClawPath, arguments: ["gateway", "stop"], timeout: 15)
        AppLogger.gateway.info("停止结果：exitCode=\(result.exitCode)")
        return result
    }
    
    @discardableResult
    func restart() async throws -> CommandResult {
        AppLogger.gateway.info("重启 Gateway...")
        let result = try await ShellRunner.run(command: openClawPath, arguments: ["gateway", "restart"], timeout: 30)
        AppLogger.gateway.info("重启结果：exitCode=\(result.exitCode)")
        return result
    }
}


// MARK: - 2. LaunchAgentService (开机自启服务)

/// launchd 开机自启管理服务
final class LaunchAgentService {
    private let config: LaunchAgentConfig
    
    init(openClawPath: String) {
        self.config = LaunchAgentConfig.openClawGateway(openClawPath: openClawPath)
    }
    
    var isEnabled: Bool {
        guard PlistWriter.exists(config: config) else { return false }
        return isRegisteredInLaunchctl()
    }
    
    private func isRegisteredInLaunchctl() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["list", config.label]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        process.environment = ProcessInfo.processInfo.environment
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch { return false }
    }
    
    func enable() throws { try register(runAtLoad: true) }
    
    func disable() throws {
        AppLogger.service.info("禁用开机自启...")
        if isRegisteredInLaunchctl() {
            try? runLaunchctl(["unload", config.plistFilePath])
        }
        try PlistWriter.remove(config: config)
    }

    func ensureLoaded() throws {
        if !isEnabled {
            AppLogger.service.info("检测到服务未加载，正在执行静默注册...")
            try register(runAtLoad: false)
        }
    }

    private func register(runAtLoad: Bool) throws {
        createLogsDirectoryIfNeeded()
        
        if isRegisteredInLaunchctl() {
            try? runLaunchctl(["unload", config.plistFilePath])
        }
        
        let targetConfig = LaunchAgentConfig(
            label: config.label, programPath: config.programPath, arguments: config.arguments,
            runAtLoad: runAtLoad, keepAlive: config.keepAlive, stdoutPath: config.stdoutPath,
            stderrPath: config.stderrPath, environmentVariables: config.environmentVariables
        )
        
        try PlistWriter.write(targetConfig)
        try runLaunchctl(["load", config.plistFilePath])
    }
    
    private func runLaunchctl(_ args: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = args
        process.environment = ProcessInfo.processInfo.environment
        
        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus != 0 {
                throw LaunchAgentError.launchctlFailed("退出码：\(process.terminationStatus)")
            }
        } catch {
            throw LaunchAgentError.launchctlFailed(error.localizedDescription)
        }
    }
    
    private func createLogsDirectoryIfNeeded() {
        let logsDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs/OpenClawBar")
        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
    }
}

enum LaunchAgentError: Error, LocalizedError {
    case launchctlFailed(String)
    var errorDescription: String? {
        if case .launchctlFailed(let msg) = self { return "launchctl 操作失败：\(msg)" }
        return nil
    }
}


// MARK: - 3. OpenClawPathService (路径探测服务)

/// openclaw 可执行文件路径检测服务
final class OpenClawPathService {
    private static let searchPaths: [String] = [
        "/opt/homebrew/bin/openclaw",
        "/usr/local/bin/openclaw",
        "/usr/bin/openclaw",
        "\(NSHomeDirectory())/.npm-global/bin/openclaw",
        "\(NSHomeDirectory())/.local/bin/openclaw",
        "\(NSHomeDirectory())/bin/openclaw"
    ]
    
    static func detectPath() -> String? {
        let customPath = AppSettings.shared.customOpenClawPath
        if !customPath.isEmpty, FileManager.default.fileExists(atPath: customPath) {
            AppLogger.info("使用用户指定路径：\(customPath)")
            return customPath
        }
        
        for path in searchPaths {
            if FileManager.default.fileExists(atPath: path) {
                AppLogger.info("自动检测到 openclaw 路径：\(path)")
                return path
            }
        }
        
        if let whichResult = findViaWhich() {
            AppLogger.info("通过 which 检测到 openclaw 路径：\(whichResult)")
            return whichResult
        }
        
        AppLogger.error("未找到 openclaw 可执行文件，请在设置中手动指定路径")
        return nil
    }
    
    private static func findViaWhich() -> String? {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["openclaw"]
        process.standardOutput = pipe
        process.environment = ProcessInfo.processInfo.environment
        
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let validPath = path, !validPath.isEmpty, FileManager.default.fileExists(atPath: validPath) else { return nil }
            return validPath
        } catch { return nil }
    }
    
    static func validate(path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path) && FileManager.default.isExecutableFile(atPath: path)
    }
}


// MARK: - 4. StatusPollingService (状态轮询服务)

/// Gateway 状态定时轮询服务
final class StatusPollingService: ObservableObject {
    @Published private(set) var currentStatus: GatewayStatus = .unknown
    private let gatewayService: GatewayService
    private var pollingTask: Task<Void, Never>?
    
    init(gatewayService: GatewayService) { self.gatewayService = gatewayService }
    
    func startPolling(interval: TimeInterval? = nil) {
        stopPolling()
        let pollingInterval = interval ?? AppSettings.shared.pollingInterval
        AppLogger.service.info("启动状态轮询，间隔 \(pollingInterval) 秒")
        
        pollingTask = Task {
            await refresh()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
                if !Task.isCancelled { await refresh() }
            }
        }
    }
    
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
        AppLogger.service.info("状态轮询已停止")
    }
    
    func refresh() async {
        let status = await gatewayService.getStatus()
        await MainActor.run { self.currentStatus = status }
    }
    
    deinit { stopPolling() }
}


// MARK: - 5. VersionService (版本检测服务)

/// 版本信息获取服务
final class VersionService {
    private let openClawPath: String
    init(openClawPath: String) { self.openClawPath = openClawPath }
    
    func getVersion() async -> String {
        do {
            let result = try await ShellRunner.run(command: openClawPath, arguments: ["--version"], timeout: 5)
            let trimmed = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("openclaw/") {
                return String(trimmed.dropFirst("openclaw/".count))
            }
            return trimmed.isEmpty ? "未知" : trimmed
        } catch {
            AppLogger.service.error("获取版本号失败：\(error.localizedDescription)")
            return "未知"
        }
    }
}
