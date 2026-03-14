//
//  GeneralSettingsTab.swift
//  
//  Purpose:
//      高级设置 - 通用选项
// 
//  Created by Dhgaj on 2026-03-14.
//  Modified by Dhgaj on 2026-03-14.
// 

import SwiftUI

struct GeneralSettingsTab: View {
    
    @EnvironmentObject private var viewModel: SettingsViewModel

    var body: some View {
        Form {
            // 执行路径
            Section("OpenClaw 执行路径") {
                VStack(alignment: .leading, spacing: 10) {
                    
                    // 已检测路径卡片
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "terminal.fill")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("当前正在使用")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(viewModel.detectedPath)
                                .font(.system(size: 11, design: .monospaced))
                                .textSelection(.enabled)
                                .lineLimit(2)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                    // 自定义路径输入
                    VStack(alignment: .leading, spacing: 6) {
                        Text("自定义路径")
                        HStack(spacing: 8) {
                            TextField("留空则使用系统自动检测", text: $viewModel.customPath)
                                .textFieldStyle(.roundedBorder)
                            Button("选择…") { viewModel.browseForOpenClawPath() }
                                .buttonStyle(.bordered)
                        }
                    }

                    // 路径验证标签
                    if !viewModel.pathValidationMessage.isEmpty {
                        let status = PathValidationStatus.from(viewModel.pathValidationMessage)
                        let text = PathValidationStatus.strippedMessage(viewModel.pathValidationMessage)
                        HStack(spacing: 4) {
                            if status != .none {
                                Image(systemName: status.icon)
                                    .foregroundStyle(status.color)
                                    .imageScale(.small)
                            }
                            Text(text)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.leading, 2)
                    }
                }
                .padding(.vertical, 4)
            }
            
            // 状态监控频率
            Section("状态监控") {
                LabeledContent("检测频率") {
                    HStack(spacing: 12) {
                        Slider(value: $viewModel.pollingInterval, in: 5...60, step: 5)
                            .controlSize(.mini)
                        Text("\(Int(viewModel.pollingInterval)) s")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.tint)
                            .monospacedDigit()
                            .frame(width: 38, alignment: .trailing)
                    }
                    .frame(width: 220)
                }
            }
            
            // 全局通知开关
            Section("全局通知") {
                Toggle("接收 Gateway 状态变更通知", isOn: $viewModel.notificationsEnabled)
                    .toggleStyle(.switch)
            }
        }
        .formStyle(.grouped)
        .onChange(of: viewModel.pollingInterval) { _, _ in viewModel.saveSettings() }
        .onChange(of: viewModel.notificationsEnabled) { _, _ in viewModel.saveSettings() }
        .onChange(of: viewModel.customPath) { _, _ in viewModel.saveSettings() }
    }
}
