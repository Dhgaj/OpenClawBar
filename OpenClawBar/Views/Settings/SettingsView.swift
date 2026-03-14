//
//  SettingsView.swift
//  
//  Purpose:
//      设置面板视图：通过原生 TabView 将配置逻辑内聚于单文件，告别碎片化物理文件堆叠。
// 
//  Created by Dhgaj on 2026-03-12.
//  Modified by Dhgaj on 2026-03-14.
// 

import SwiftUI

// MARK: - 主设置面板

/// 设置面板根视图，通过 Settings Scene 或 openWindow(id:) 打开
struct SettingsView: View {

    // SettingsViewModel 作用域为整个设置面板
    @StateObject private var settingsViewModel = SettingsViewModel()
    @EnvironmentObject private var menuViewModel: MenuBarViewModel

    var body: some View {
        TabView {
            // 1. 通用设置 Tab
            GeneralSettingsTab()
                .environmentObject(settingsViewModel)
                .tabItem { Label("通用", systemImage: "gearshape") }
                .tag(0)

            // 2. 启动设置 Tab
            StartupSettingsTab()
                .environmentObject(menuViewModel)
                .tabItem { Label("启动", systemImage: "clock.arrow.circlepath") }
                .tag(1)

            // 3. 关于 Tab
            AboutTab()
                .tabItem { Label("关于", systemImage: "info.circle") }
                .tag(2)
        }
        .padding(.top, 10) // 增加顶部间距
        .frame(minWidth: 480, maxWidth: 600, minHeight: 380, maxHeight: 500)
    }
}

// MARK: - 局部状态定义：路径验证状态

enum PathValidationStatus {
    case valid, invalid, none

    var icon: String {
        switch self {
        case .valid: return "checkmark.circle.fill"
        case .invalid: return "xmark.circle.fill"
        case .none: return ""
        }
    }

    var color: Color {
        switch self {
        case .valid: return .green
        case .invalid: return .red
        case .none: return .clear
        }
    }

    static func from(_ message: String) -> PathValidationStatus {
        if message.hasPrefix("✅") { return .valid }
        if message.hasPrefix("❌") || message.hasPrefix("⚠️") { return .invalid }
        return .none
    }

    static func strippedMessage(_ message: String) -> String {
        message
            .replacingOccurrences(of: "✅ ", with: "")
            .replacingOccurrences(of: "❌ ", with: "")
            .replacingOccurrences(of: "⚠️ ", with: "")
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(MenuBarViewModel())
}
