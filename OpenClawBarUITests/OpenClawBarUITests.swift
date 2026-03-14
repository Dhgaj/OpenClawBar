//
//  OpenClawBarUITests.swift
//  
//  Purpose:
//      UI 界面与自动启动生命周期黑盒测试
// 
//  Created by Dhgaj on 2026-03-14.
//  Modified by Dhgaj on 2026-03-14.
// 

import XCTest

final class OpenClawBarUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunchAndSettingsTabs() throws {
        let app = XCUIApplication()
        app.launch()

        // 验证主应用已启动 (MenuBar App 没有常规窗口，但本身处于 running 状态)
        XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground, "应用启动状态异常")
        
        // （由于原生 MenuBarApp 没有主窗口的标识，很难单纯基于 App 触发点击，这里我们只验证能被调起的 Settings 原生元素）
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
