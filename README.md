# 🦞 OpenClawBar

> [!IMPORTANT]
> **注意**：本项目目前仍处于开发阶段（In Development），部分功能可能尚不完善。

OpenClawBar 是一款专为 macOS 设计的菜单栏应用，旨在为用户提供一个优雅且高效的方式来监控和管理 **OpenClaw Gateway** 服务。

---

## ✨ 核心功能

- **🚀 实时监控**：在菜单栏通过 🦞 图标实时查看 Gateway 运行状态。
- **⚙️ 快捷控制**：支持一键 开启、停止、重启 Gateway，无需打开终端。
- **🔌 开机自启**：基于 `launchd` 实现，支持登录系统时自动静默启动服务。
- **🛠️ 自定义配置**：可指定非标准路径的 OpenClaw 可执行文件，配置通知偏好与轮询频率。

---

## 🛠️ 快速开始

### 系统要求

- macOS 13.0 (Ventura) 或更高版本

### 安装与运行

1. **克隆项目**：
   ```bash
   git clone https://github.com/Dhgaj/OpenClawBar.git
   cd OpenClawBar
   ```
2. **构建与运行**：
   - 使用 Xcode 打开 `OpenClawBar.xcodeproj`。
   - 在 Xcode 中执行 **Clean Build (⇧⌘K)**。
   - 点击 **Run (⌘R)**。

### 🚨 重要：关闭沙盒访问权限

由于 OpenClawBar 需要调用系统路径下的 `/usr/local/bin` 或 `/opt/homebrew/bin`，应用必须运行在 **Non-Sandboxed** 模式下。

项目已包含 `OpenClawBar.entitlements`。如果构建失败，请确保在 Xcode 目标设置的 **Build Settings** 中，将 `Code Signing Entitlements` 指向此文件，并确认 **App Sandbox** 已设为 `NO`。

---

## 🏗️ 技术栈

- **Language**: Swift 6.0
- **UI Framework**: SwiftUI
- **Concurrency**: Swift Concurrency (Async/Await)
- **Persistence**: UserDefaults / launchd
- **Logging**: OSLog

---

## 🦞 关于 OpenClawBar

OpenClawBar 是一个强大且灵活的项目。本项目旨在为其用户提供更好的本地化交互体验。

## 📄 许可证

本项目采用 [MIT 许可证](./LICENSE) 开源。

*Built with ❤️ and 🦞 by Dhgaj !*
