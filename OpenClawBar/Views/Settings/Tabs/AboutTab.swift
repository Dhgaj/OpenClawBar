//
//  AboutTab.swift
//  
//  Purpose:
//      关于应用 Tab
// 
//  Created by Dhgaj on 2026-03-14.
//  Modified by Dhgaj on 2026-03-14.
// 

import SwiftUI

struct AboutTab: View {

    private struct LinkItem: Identifiable {
        let id = UUID()
        let label: String
        let icon: String
        let urlString: String
    }

    private let links: [LinkItem] = [
        LinkItem(label: "OpenClaw 官方网站", icon: "safari", urlString: "https://openclaw.ai"),
        LinkItem(label: "OpenClawBar 开源地址", icon: "link", urlString: "https://github.com/Dhgaj/OpenClawBar"),
    ]

    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "Version \(version) (Build \(build))"
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // 品牌区域
            ZStack {
                Circle()
                    .fill(Color.orange.gradient.opacity(0.1))
                    .frame(width: 80, height: 80)
                Text("🦞").font(.system(size: 50))
            }
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            
            Spacer().frame(height: 20)

            // 版本区域
            VStack(spacing: 4) {
                Text("OpenClaw Bar")
                    .font(.title3.bold())
                Text(versionText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer().frame(height: 16)
            Divider().frame(width: 200)
            Spacer().frame(height: 16)

            // 外部链接区域
            VStack(spacing: 8) {
                ForEach(links) { item in
                    if let url = URL(string: item.urlString) {
                        Link(destination: url) {
                            Label(item.label, systemImage: item.icon)
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundStyle(.tint)
                    }
                }
            }

            Spacer()

            // 底部版权
            Text("Built with ❤️ and 🦞 by Dhgaj")
                .font(.system(size: 10, weight: .light))
                .foregroundStyle(.secondary.opacity(0.6))
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
