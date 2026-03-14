//
//  MenuBarView.swift
//  
//  Purpose:
//      菜单栏根视图：优化版 UI 设计，使用 Edge-to-Edge 分隔线和原生 Accent Color 悬停响应，带来极致的流畅与原生体验。
// 
//  Created by Dhgaj on 2026-03-12.
//  Modified by Dhgaj on 2026-03-14.
// 

import SwiftUI

/// 菜单栏主视图（MenuBarExtra 的内容）
struct MenuBarView: View {
    
    @EnvironmentObject private var viewModel: MenuBarViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // 1. 顶部状态与版本指示器
            statusHeader
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
            
            // 2. 错误反馈
            if let error = viewModel.errorMessage {
                ErrorBannerView(message: error) {
                    viewModel.errorMessage = nil
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            
            Divider().background(Color.secondary.opacity(0.2))
            
            // 3. 第一控制组：生命周期与刷新
            VStack(spacing: 2) {
                actionButton(title: "立即刷新", icon: "arrow.clockwise") {
                    viewModel.refreshNow()
                }
                
                actionButton(title: "启动 Gateway", icon: "play.fill", disabled: !viewModel.status.canStart || viewModel.isLoading) {
                    viewModel.startGateway()
                }
                
                actionButton(title: "停止 Gateway", icon: "stop.fill", disabled: !viewModel.status.canStop || viewModel.isLoading) {
                    viewModel.stopGateway()
                }
                
                actionButton(title: "重启 Gateway", icon: "arrow.triangle.2.circlepath", disabled: !viewModel.status.canStop || viewModel.isLoading) {
                    viewModel.restartGateway()
                }
            }
            .padding(8)
            
            Divider().background(Color.secondary.opacity(0.2))
            
            // 4. 第二控制组：网关配置与系统操作
            VStack(spacing: 2) {
                // 自启设置
                HStack {
                    Label {
                        Text("开机自启")
                            .font(.system(size: 13, weight: .medium))
                    } icon: {
                        Image(systemName: "macwindow.badge.plus")
                            .font(.system(size: 13, weight: .medium))
                            .frame(width: 16)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { viewModel.isAutoStartEnabled },
                        set: { _ in viewModel.toggleAutoStart() }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .tint(.accentColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                
                // 设置
                SettingsLink {
                    actionButtonRaw(title: "偏好设置...", icon: "gearshape")
                }
                .buttonStyle(HoverButtonStyle())
            }
            .padding(8)
            
            Divider().background(Color.secondary.opacity(0.2))
            
            // 5. 退出
            VStack(spacing: 2) {
                actionButton(title: "退出 OpenClaw", icon: "power", role: .destructive) {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(8)
        }
        .frame(width: 250)
        .backgroundMaterial(.popover) // 恢复原生材质背景，更通透
    }
}

// MARK: - 局部视图与组件 Extension
extension MenuBarView {
    
    /// 顶部状态指示栏：状态发光点与版本 Badge
    private var statusHeader: some View {
        HStack(alignment: .top, spacing: 8) {
            // 原生状态发光小圆点
            Circle()
                .fill(viewModel.status.color)
                .frame(width: 8, height: 8)
                .shadow(color: viewModel.status.isRunning ? viewModel.status.color.opacity(0.6) : .clear, radius: 4)
                .padding(.top, 4.5)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.status.displayText)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(viewModel.versionString)
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(.secondary.opacity(0.8))
            }
            
            Spacer()
        }
    }
    
    /// 获取一个纯布局包裹的按钮内容 (给 SettingsLink 使用)
    private func actionButtonRaw(title: String, icon: String, role: ButtonRole? = nil) -> some View {
        Label {
            Text(title)
                .font(.system(size: 13, weight: .medium))
        } icon: {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 16)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
    
    /// 生成标准的原生排版菜单操作按钮
    private func actionButton(
        title: String,
        icon: String,
        role: ButtonRole? = nil,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            actionButtonRaw(title: title, icon: icon, role: role)
        }
        .buttonStyle(HoverButtonStyle(role: role, disabled: disabled))
        .disabled(disabled)
    }
}

/// 一个极致模拟 macOS 原生菜单选项的悬停按钮样式
struct HoverButtonStyle: ButtonStyle {
    var role: ButtonRole? = nil
    var disabled: Bool = false
    
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(backColor(isPressed: configuration.isPressed))
            )
            .foregroundColor(foreColor(isPressed: configuration.isPressed))
            .onHover { hover in
                withAnimation(.easeOut(duration: 0.1)) {
                    isHovered = hover
                }
            }
    }
    
    private func backColor(isPressed: Bool) -> Color {
        if disabled { return .clear }
        if role == .destructive {
            return isPressed ? Color.red.opacity(0.9) : (isHovered ? Color.red : .clear)
        }
        return isPressed ? Color.accentColor.opacity(0.9) : (isHovered ? Color.accentColor : .clear)
    }
    
    private func foreColor(isPressed: Bool) -> Color {
        if disabled { return .secondary.opacity(0.4) }
        if isHovered || isPressed { return .white } // 悬停或按下时统一变白
        if role == .destructive { return .red } // 未悬停时的警告色
        return .primary
    }
}

#Preview {
    MenuBarView()
        .environmentObject(MenuBarViewModel())
}
