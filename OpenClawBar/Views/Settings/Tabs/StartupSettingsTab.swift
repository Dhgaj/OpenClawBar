//
//  StartupSettingsTab.swift
//  
//  Purpose:
//      启动配置 Tab
// 
//  Created by Dhgaj on 2026-03-14.
//  Modified by Dhgaj on 2026-03-14.
// 

import SwiftUI

struct StartupSettingsTab: View {
    
    @EnvironmentObject private var menuViewModel: MenuBarViewModel

    private var autoStartBinding: Binding<Bool> {
        Binding(
            get: { menuViewModel.isAutoStartEnabled },
            set: { _ in menuViewModel.toggleAutoStart() }
        )
    }

    var body: some View {
        Form {
            Section {
                Toggle(isOn: autoStartBinding) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("登录时自动启动")
                            .font(.body)
                        Text("开启后将在系统登录时自动运行 Gateway 服务")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
                .padding(.vertical, 4)
            } header: {
                Text("启动行为")
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Label {
                        Text("通过用户级 LaunchAgent 实现，无需管理员权限。")
                    } icon: {
                        Image(systemName: "info.circle")
                            .imageScale(.small)
                    }
                    HStack(spacing: 4) {
                        Text("配置文件：")
                        Text("~/Library/LaunchAgents/ai.openclaw.gateway.plist")
                            .fontDesign(.monospaced)
                            .textSelection(.enabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            }
        }
        .formStyle(.grouped)
    }
}
