//
//  CommonComponents.swift
//  
//  Purpose:
//      收纳散落的细小公共 UI 组件
// 
//  Created by Dhgaj on 2026-03-12.
//  Modified by Dhgaj on 2026-03-14.
// 

import SwiftUI

// MARK: - 1. ErrorBannerView (错误横幅)

/// 错误提示横幅（操作失败时在菜单顶部显示）
struct ErrorBannerView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.system(size: 11))
            
            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(.red)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}


// MARK: - 2. LoadingSpinnerView (转圈动画)

/// 旋转加载指示器（操作执行中使用）
struct LoadingSpinnerView: View {
    @State private var isRotating = false
    
    var body: some View {
        Image(systemName: "arrow.2.circlepath")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.secondary)
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isRotating)
            .onAppear { isRotating = true }
    }
}


// MARK: - 3. SectionHeaderView (小标题)

/// 分组标题视图（用于设置面板等列表分区）
struct SectionHeaderView: View {
    let title: String
    var systemImage: String? = nil
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = systemImage {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
    }
}


// MARK: - 4. StatusBadgeView (带光晕的状态点)

/// 状态指示圆点（根据 GatewayStatus 自动匹配颜色）
struct StatusBadgeView: View {
    let status: GatewayStatus
    var size: CGFloat = 8
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.5
    
    var body: some View {
        ZStack {
            Circle()
                .fill(status.color.opacity(0.3))
                .frame(width: size + 6, height: size + 6)
                .blur(radius: 4)
            
            Circle()
                .fill(status.color.gradient)
                .frame(width: size, height: size)
                .overlay(
                    Circle().stroke(.white.opacity(0.3), lineWidth: 1)
                )
            
            if status == .running {
                Circle()
                    .stroke(status.color.opacity(0.5), lineWidth: 1.5)
                    .scaleEffect(pulseScale)
                    .opacity(pulseOpacity)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                            pulseScale = 2.0
                            pulseOpacity = 0
                        }
                    }
            }
        }
    }
}


// MARK: - 5. VisualEffectView (原生毛玻璃材质)

/// 为 SwiftUI 提供 macOS 系统级的磨砂玻璃底色（Vibrancy）
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    var state: NSVisualEffectView.State = .followsWindowActiveState

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

extension View {
    /// 背景磨砂玻璃快捷装饰器
    func backgroundMaterial(_ material: NSVisualEffectView.Material = .menu) -> some View {
        self.background(VisualEffectView(material: material, blendingMode: .behindWindow))
    }
}

// MARK: - Previews
#Preview {
    VStack(spacing: 20) {
        ErrorBannerView(message: "这是错误测试", onDismiss: {})
        LoadingSpinnerView()
        SectionHeaderView(title: "基础组件", systemImage: "star.fill")
        HStack {
            StatusBadgeView(status: .running)
            StatusBadgeView(status: .stopped)
            StatusBadgeView(status: .error("error"))
        }
    }
    .padding()
    .backgroundMaterial(.popover)
}
