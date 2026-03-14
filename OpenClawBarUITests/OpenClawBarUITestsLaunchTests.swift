//
//  OpenClawBarUITestsLaunchTests.swift
//  
//  Purpose:
//      应用启动性能与截图验证测试
// 
//  Created by Dhgaj on 2026-03-12.
//  Modified by Dhgaj on 2026-03-14.
// 

import XCTest

final class OpenClawBarUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
