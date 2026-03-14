//
//  OpenClawBarTests.swift
//  
//  Purpose:
//      核心逻辑与数据模型单元测试用例
// 
//  Created by Dhgaj on 2026-03-14.
//  Modified by Dhgaj on 2026-03-14.
// 

import Testing
@testable import OpenClawBar

struct OpenClawBarTests {

    // MARK: - CommandResult Tests
    
    @Test("CommandResult: 成功状态与输出解析")
    func testCommandResultSuccess() {
        let result = CommandResult(exitCode: 0, stdout: "Running", stderr: "", duration: 0.1)
        #expect(result.isSuccess == true)
        #expect(result.combinedOutput == "Running")
    }
    
    @Test("CommandResult: 失败状态与综合输出")
    func testCommandResultFailure() {
        let result = CommandResult(exitCode: 1, stdout: "", stderr: "Error occurred", duration: 0.5)
        #expect(result.isSuccess == false)
        #expect(result.combinedOutput == "Error occurred")
    }
    
    @Test("CommandResult: 优先提取标准输出")
    func testCommandResultOutputPriority() {
        let result = CommandResult(exitCode: 0, stdout: "Success\n", stderr: "Some warnings", duration: 0.2)
        #expect(result.combinedOutput == "Success") // 测试是否裁剪了换行符，且无视了 stderr
    }

    // MARK: - GatewayStatus Tests
    
    @Test("GatewayStatus: 运行状态属性检查")
    func testGatewayStatusRunning() {
        let status = GatewayStatus.running
        #expect(status.isRunning == true)
        #expect(status.isStopped == false)
        #expect(status.isError == false)
        #expect(status.canStart == false)
        #expect(status.canStop == true)
    }
    
    @Test("GatewayStatus: 停止状态属性检查")
    func testGatewayStatusStopped() {
        let status = GatewayStatus.stopped
        #expect(status.isRunning == false)
        #expect(status.isStopped == true)
        #expect(status.isError == false)
        #expect(status.canStart == true)
        #expect(status.canStop == false)
    }

    @Test("GatewayStatus: UI 展示文本是否正确")
    func testGatewayStatusDisplayText() {
        #expect(GatewayStatus.running.displayText == "运行中")
        #expect(GatewayStatus.stopped.displayText == "已停止")
        #expect(GatewayStatus.error("Timeout").displayText == "异常：Timeout")
        #expect(GatewayStatus.unknown.displayText == "检测中")
    }

    // MARK: - LaunchAgentConfig Tests
    
    @Test("LaunchAgentConfig: 默认生成的配置文件结构")
    func testLaunchAgentConfigStructure() {
        let path = "/mock/path/openclaw"
        let config = LaunchAgentConfig.openClawGateway(openClawPath: path)
        
        #expect(config.label == "ai.openclaw.gateway")
        #expect(config.programPath == path)
        #expect(config.arguments == ["gateway", "run"])
        #expect(config.runAtLoad == true)
        #expect(config.keepAlive == true)
        #expect(config.plistFileName == "ai.openclaw.gateway.plist")
        
        let expectedEnv = [
            "/usr/local/bin",
            "/opt/homebrew/bin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin"
        ].joined(separator: ":")
        
        #expect(config.environmentVariables?["PATH"] == expectedEnv)
    }
}

