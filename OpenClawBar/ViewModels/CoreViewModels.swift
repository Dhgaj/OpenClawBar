//
//  CoreViewModels.swift
//  
//  Purpose:
//      UI 响应式状态模型统一入口
// 
//  Created by Dhgaj on 2026-03-12.
//  Modified by Dhgaj on 2026-03-14.
// 

import AppKit
import SwiftUI
import Combine

// MARK: - MenuBarViewModel (主菜单数据模型)

/// 菜单栏主视图模型
@MainActor
final class MenuBarViewModel: ObservableObject {
    @Published private(set) var status: GatewayStatus = .unknown
    @Published var isAutoStartEnabled: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var versionString: String = "..."
    @Published var errorMessage: String? = nil
    
    private var gatewayService: GatewayService?
    private var launchAgentService: LaunchAgentService?
    private var versionService: VersionService?
    private var pollingService: StatusPollingService?
    private var cancellables = Set<AnyCancellable>()
    
    init() { setupServices() }
    
    private func setupServices() {
        guard let path = OpenClawPathService.detectPath() else {
            AppLogger.error("未找到 openclaw，部分功能不可用")
            status = .error("未找到 openclaw 可执行文件，请在设置中配置路径")
            return
        }
        
        gatewayService     = GatewayService(openClawPath: path)
        launchAgentService = LaunchAgentService(openClawPath: path)
        versionService     = VersionService(openClawPath: path)
        
        let pService = StatusPollingService(gatewayService: gatewayService!)
        self.pollingService = pService
        
        pService.$currentStatus
            .receive(on: DispatchQueue.main)
            .assign(to: &$status)
        
        pService.startPolling()
        isAutoStartEnabled = launchAgentService?.isEnabled ?? false
        
        Task { versionString = await versionService?.getVersion() ?? "未知" }
    }
    
    func startGateway() {
        guard let service = gatewayService else { return }
        performAction {
            let result = try await service.start()
            if result.isSuccess { NotificationHelper.notifyGatewayStarted() }
            else { throw GatewayActionError.operationFailed(result.combinedOutput) }
        }
    }
    
    func stopGateway() {
        guard let service = gatewayService else { return }
        performAction {
            let result = try await service.stop()
            if result.isSuccess { NotificationHelper.notifyGatewayStopped() }
            else { throw GatewayActionError.operationFailed(result.combinedOutput) }
        }
    }
    
    func restartGateway() {
        guard let service = gatewayService else { return }
        performAction {
            let result = try await service.restart()
            if !result.isSuccess { throw GatewayActionError.operationFailed(result.combinedOutput) }
        }
    }
    
    func toggleAutoStart() {
        guard let service = launchAgentService else { return }
        Task {
            do {
                if isAutoStartEnabled { try service.disable() }
                else { try service.enable() }
                isAutoStartEnabled = service.isEnabled
            } catch {
                errorMessage = error.localizedDescription
                AppLogger.error("开机自启切换失败：\(error.localizedDescription)")
            }
        }
    }
    
    func refreshNow() { Task { await pollingService?.refresh() } }
    
    private func performAction(_ action: @escaping () async throws -> Void) {
        Task {
            isLoading = true
            errorMessage = nil
            do { try await action() }
            catch {
                errorMessage = error.localizedDescription
                NotificationHelper.notifyError(message: error.localizedDescription)
            }
            await pollingService?.refresh()
            isLoading = false
        }
    }
}

private enum GatewayActionError: Error, LocalizedError {
    case operationFailed(String)
    var errorDescription: String? {
        if case .operationFailed(let output) = self { return "操作失败：\(output)" }
        return nil
    }
}


// MARK: - SettingsViewModel (设置面板数据模型)

/// 设置面板视图模型
final class SettingsViewModel: ObservableObject {
    @Published var customPath: String = ""
    @Published private(set) var detectedPath: String = "检测中..."
    @Published var pollingInterval: Double = 10
    @Published var notificationsEnabled: Bool = true
    @Published private(set) var pathValidationMessage: String = ""

    private let settings = AppSettings.shared

    init() {
        loadSettings()
        detectPath()
    }

    private func loadSettings() {
        customPath           = settings.customOpenClawPath
        pollingInterval      = settings.pollingInterval
        notificationsEnabled = settings.notificationsEnabled
    }

    func saveSettings() {
        settings.customOpenClawPath   = customPath
        settings.pollingInterval      = pollingInterval
        settings.notificationsEnabled = notificationsEnabled
        AppLogger.info("设置已保存")
    }

    func detectPath() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let path = OpenClawPathService.detectPath()
            DispatchQueue.main.async {
                guard let self else { return }
                if let path {
                    self.detectedPath = path
                    self.pathValidationMessage = "✅ 路径有效"
                } else {
                    self.detectedPath = "未找到"
                    self.pathValidationMessage = "❌ 未检测到 openclaw，请手动指定路径"
                }
            }
        }
    }

    func browseForOpenClawPath() {
        let panel = NSOpenPanel()
        panel.title = "选择 openclaw 可执行文件"
        panel.message = "请选择 openclaw 的完整可执行文件路径"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        if panel.runModal() == .OK, let url = panel.url {
            customPath = url.path
            if OpenClawPathService.validate(path: url.path) {
                pathValidationMessage = "✅ 路径有效"
            } else {
                pathValidationMessage = "⚠️ 所选文件可能不是有效的 openclaw"
            }
        }
    }
}
