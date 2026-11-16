# iOS Lab

一个在 **Windows** 上开发、在 **macOS CI** 上构建与模拟的 iOS 工程模板。

- `apps/flutter_app` — Flutter 应用（iOS + Web），本地可分析/测试/预览
- `apps/native_app` — SwiftUI 原生应用，用 XcodeGen 从 `project.yml` 生成工程
- `.github/workflows/ios.yml` — `macos-26` 上构建、单测、启动 iOS Simulator、截图、上传产物

## 快速开始

```bat
:: 本地：格式 + 分析 + 测试
D:\iOSLab\ioslab.cmd check

:: 本地：iPhone 视口预览（热重载）
D:\iOSLab\ioslab.cmd preview

:: 本地：1179x2556 截图
D:\iOSLab\ioslab.cmd shot
```

## 工程结构

```
apps/flutter_app
├── lib/
│   ├── main.dart          # CupertinoApp
│   ├── lab_page.dart      # UI
│   └── lab_model.dart     # 纯 Dart 模型（可单测）
└── test/                  # 单元 + Widget 测试

apps/native_app
├── Sources/               # SwiftUI + 纯模型
├── Tests/                 # XCTest
└── project.yml            # XcodeGen 工程定义（不提交 .xcodeproj）

scripts/
├── ios-sim.sh             # 在 macOS 上选模拟器 / 安装 / 启动 / 截图
├── serve_web.dart         # 极简静态服务器（供截图）
├── cdp_shot.dart          # DevTools Protocol 精确设备截图
└── validate_workflows.dart# workflow 结构校验（离线可用）
```

## CI

推送到 `main` 或手动触发后：

- `flutter-ios`：`flutter analyze` → `flutter test` → `flutter build ios --simulator` →
  Simulator 启动 → 亮/暗截图 → `.app` 产物
- `native-ios`：`xcodegen generate` → `xcodebuild test` → 截图 → `.app` + `xcresult`

产物在 Actions run 页面的 Artifacts 中。可选的 Appetize 上传需手动触发并配置
`APPETIZE_API_KEY`。

## 说明

- Xcode 工程由 `project.yml` 生成，**不要提交**（`.gitignore` 已排除）。
- iOS 构建只能在 macOS 上执行；Windows 侧负责编辑、静态检查、测试与预览。
- 详细方案见 `docs/PLAN.md`，日常使用见 `docs/USAGE.md`，回滚见 `docs/ROLLBACK.md`。
