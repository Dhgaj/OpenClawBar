//
//  OpenClawBarApp.swift
//  
//  Purpose:
//      应用入口：以菜单栏形式运行，不显示 Dock 图标
// 
//  Created by Dhgaj on 2026-03-12.
//  Modified by Dhgaj on 2026-03-14.
// 

import SwiftUI

@main
struct OpenClawBarApp: App {
    
    // 菜单栏视图的 ViewModel，全局单例
    @StateObject private var menuBarViewModel = MenuBarViewModel()
    
    var body: some Scene {
        // 菜单栏图标
        MenuBarExtra {
            MenuBarView()
                .environmentObject(menuBarViewModel)
        } label: {
            Text(menuBarViewModel.status.menuBarEmoji)
                .grayscale(menuBarViewModel.status.isRunning ? 0 : 1)
                .opacity(menuBarViewModel.status.isRunning ? 1.0 : 0.6)
        }
        .menuBarExtraStyle(.window)
        
        // 原生设置场景
        Settings {
            SettingsView()
                .environmentObject(menuBarViewModel)
        }
    }
}
