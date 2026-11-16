# iOS Lab on Windows — 实施计划（v2，已按实测修正）

> 目标：在这台 Windows 笔记本上建立一套**完善、简洁、专业**的 iOS 应用开发 / 测试 / 模拟环境，
> 并且**所有改动都可干净回滚**。
>
> 本文件是决策与执行记录；回滚见 [`ROLLBACK.md`](ROLLBACK.md)，日常使用见 [`USAGE.md`](USAGE.md)，
> 实机自检见 `D:\iOSLab\state\verify-report.json`。

---

## 1. 结论先行

iOS 应用的**编译、签名、iOS Simulator 运行**在技术上只能发生在 macOS + Xcode 上。
Windows 上不存在合法的"iOS 模拟器软件"。因此本方案不追求"把 Xcode 装进 Windows"，
而是构建一条**三段式、职责清晰**的链路：

| 通道 | 位置 | 能力 | 延迟 | 成本 |
|---|---|---|---|---|
| **A. 本地即时反馈** | 本机 Windows | 代码编辑 / 静态分析 / 单元 + Widget 测试 / 真字体的 iPhone 视口预览与截图 | 秒级 | 0 |
| **B. 真实 iOS 构建 + Simulator** | GitHub Actions `macos-15-intel`（可用变量切 arm64 池） | `xcodebuild` / CocoaPods / Simulator 启动、UI 测试、截图、`.app` 产物 | 3–6 分钟（排队另计） | 公开仓库免费 |
| **C. 可交互远程模拟器** | Appetize.io | 浏览器里点按真实 iOS Simulator 运行已构建的 `.app` | 秒级 | 免费额度 30 分钟/月 |

外加**升级路径**（不默认启用，需要付费账号）：MacinCloud / MacStadium / AWS EC2 Mac 远程 Mac，
用于必须用 Xcode IDE、真机调试、签名与上架的场景。

### 为什么不选其它方案

| 方案 | 结论 | 原因 |
|---|---|---|
| Hackintosh / VMware 装 macOS | **否决** | 违反 Apple 许可（macOS 仅授权在 Apple 硬件上运行，含虚拟化）；本机 8 GB / i5-10210U / 无独显，Simulator 不可用；不可维护 |
| 在 Windows 上装"iOS 模拟器" | **不存在** | 没有合法产品能在非 Apple 硬件上运行 iOS Simulator |
| 只用 Appetize | 不够 | 必须先有 macOS 产物；免费版 3 分钟/会话、30 分钟/月 |
| 只用 GitHub Actions | 不够 | 无法交互预览、无热重载，反馈环 3–6 分钟 |
| 本地只装 Flutter | 不完整 | 拿不到真实 iOS 渲染；`flutter build ios` 在 Windows 直接拒绝执行 |

### 合规基线

- 不下载任何 macOS 镜像 / 破解工具 / 引导器。
- 不把 GitHub Actions 当交互式桌面使用（违反 ToS 的用法）。
- 只用官方渠道：Flutter 官方发布清单、Git 官方 Windows 构建的镜像副本（哈希对官方 API 校验）、
  VS Code 官方签名安装包。
- Appetize 只上传自己构建的测试 App。

---

## 2. 本机实测基线

| 项 | 值 |
|---|---|
| OS | Windows 10 Pro 21H1，Build 19043.1682 |
| CPU / RAM | Intel i5-10210U（4C8T）/ 7.8 GB |
| 磁盘 | C: 155 GB 空闲；D: 272 GB 空闲 |
| 权限 | **非管理员**（UAC 未提升）→ 全部用户态安装 |
| 已有 | Edge 157、QQBrowser、winget 1.29、OpenSSH 客户端 |
| 网络（实测） | `api.github.com`、`raw.githubusercontent.com`、`codeload.github.com`、`pub.dev`、`storage.flutter-io.cn` 可用；**`github.com` 网页与 `storage.googleapis.com` TLS 不通**；`github.com:22` 与 `ssh.github.com:443` 可握手 |
| 结论 | SDK 走 `storage.flutter-io.cn` 镜像（40 MB/s）；git 推送走 **SSH**；仓库/CI 管理走 **REST API** |

> ⚠️ Windows 10 21H1 已停止支持（全系 Windows 10 于 2025-10-14 结束支持）。不影响本方案，
> 但建议后续升级 Windows 11。不在本次范围。

---

## 3. 组件与版本（全部锁定）

| 组件 | 版本 | 安装方式 | 位置 |
|---|---|---|---|
| Flutter SDK | **3.50.0**（Dart 3.14.0，2026-11-11 stable） | 官方 zip + SHA-256 校验，CN 镜像 | `D:\iOSLab\flutter` |
| Git for Windows | 2.56.1（PortableGit） | TUNA 镜像 + GitHub API 摘要校验 | `D:\iOSLab\tools\git` |
| VS Code | **1.146.0**（user setup，已装） | 官方 CDN + Authenticode 校验 + 断点续传 | `%LOCALAPPDATA%\Programs\Microsoft VS Code` |
| 浏览器 | Edge 157（已存在） | — | 系统 |
| iOS 构建环境 | 默认 `macos-15-intel`；`macos-15`/`macos-26`（arm64）可用仓库变量 `IOS_RUNNER` 切换 | GitHub Actions | 云端 |

> **VS Code 状态**：已安装 1.146.0，签名 `CN=Microsoft Corporation` 校验通过，
> 扩展 `dart-code.dart-code`、`dart-code.flutter` 已装，用户设置指向
> `D:\iOSLab\flutter`。安装过程中 Microsoft CDN 多次限速/重置，脚本已改为
> `curl -C -` 断点续传 + 每次重试前校验 Authenticode 签名，最终一次跑通。

用户环境变量（可回滚）：

```
PUB_CACHE                  = D:\iOSLab\cache\pub
FLUTTER_STORAGE_BASE_URL   = https://storage.flutter-io.cn
PUB_HOSTED_URL             = https://pub.flutter-io.cn
PATH                      += D:\iOSLab\flutter\bin; D:\iOSLab\tools\git\cmd
```

未安装 gh CLI / actionlint：它们的发布资产托管在 `github.com`（本网络不可达）。
替代方案：git + REST API（`scripts\ci.ps1`）、Dart 写的 workflow 校验器
（`scripts\validate_workflows.dart`，复用 Flutter 自带的 `package:yaml`）。

---

## 4. 目录布局

```
D:\iOSLab\
├── ioslab.cmd                    # 唯一入口：preview / shot / check / doctor / verify / ci / uninstall
├── flutter\                      # Flutter SDK（可整体删除）
├── tools\git\                    # PortableGit（git、bash、ssh）
├── cache\{downloads,pub}\        # 安装包与 pub 缓存
├── logs\                         # 安装 / 运行日志
├── state\                        # pre-state.json、downloads.json、verify-report.json
├── docs\                         # PLAN / ROLLBACK / USAGE
├── scripts\                      # 00-preflight … 04-verify、09-uninstall、preview、shot、ci
└── projects\ioslab\              # 示例工程（git 仓库，可推到 GitHub 触发 CI）
    ├── apps\flutter_app\         # Flutter 应用（iOS + Web）
    ├── apps\native_app\          # SwiftUI 原生示例 + project.yml（XcodeGen）
    ├── scripts\                  # ios-sim.sh、serve_web.dart、cdp_shot.dart、validate_workflows.dart
    ├── .github\workflows\ios.yml
    └── docs\                     # 与 D:\iOSLab\docs 同步的副本
```

---

## 5. 关键设计

### 5.1 本地开发环（A 通道）

- `D:\iOSLab\ioslab.cmd check`：`dart format --set-exit-if-changed` + `flutter analyze --fatal-infos`
  + `flutter test`，与 CI 同门槛。
- `ioslab.cmd preview`：`flutter run -d web-server`（热重载）+ Edge `--app` 无边框窗口。
- `ioslab.cmd shot`：`flutter build web --release` → Dart 静态服务器 → **CDP 驱动 headless Edge**，
  用 `Emulation.setDeviceMetricsOverride(393×852, dsf=3)` 精确得到 1179×2556 的 iPhone 截图。
  单纯的 `--screenshot` 做不到：Chromium 会钳制窗口尺寸，`--force-device-scale-factor`
  又不改变 CSS 视口（实测 393 被钳成 482）。
- 原生 SwiftUI：源码 + `project.yml`，Windows 上可编辑 / review / diff，构建交给 CI。

### 5.2 云端构建（B 通道）

`.github/workflows/ios.yml`，两个并行 job：

1. **flutter-ios**：`macos-15`（或 `IOS_RUNNER` 指定）→ Flutter 3.50.0（cache）→ `pub get` → format → analyze → test →
   `flutter build ios --simulator` → 动态选 iPhone 模拟器 → `simctl boot/install/launch` →
   状态栏归位（9:41/满电）→ 亮/暗两张截图 → 产物上传。
2. **native-ios**：同一 runner → `brew install xcodegen` → `xcodegen generate` →
   `xcodebuild test` → 截图 → `.app`、`xcresult` 上传。

设计要点：
- **不写死设备名**：`scripts/ios-sim.sh resolve` 用 `simctl list devices available -j` 动态挑选
  可用的 iPhone，避免 iOS 版本升级后 "device not found"。
- **固定版本**：Flutter 版本与 runner 标签锁定，runner 退役只改一处。
- **公开仓库免费**：标准 GitHub-hosted runner 在公开仓库不计费；私有仓库 macOS 按 10 倍分钟计费。

### 5.3 交互式模拟（C 通道）

- 把 CI 产物 `.app` 上传 Appetize，得到浏览器内可点按的 iOS 模拟器链接。
- workflow 中该步骤默认跳过，只有手动触发且配置 `APPETIZE_API_KEY` 时执行。
- 免费版：2 设备 / 30 分钟每月 / 单次会话 3 分钟。

### 5.4 网络约束下的 GitHub 流程

| 动作 | 通道 | 状态 |
|---|---|---|
| 读仓库/运行状态、下载产物 | `api.github.com` + token | 可用 |
| push | `ssh://git@github.com`（22 或 443） | 可用（需把公钥加到 GitHub） |
| 网页 UI、登录、建 PAT | `github.com` | 本机不可达；需在手机/其它网络完成一次性配置 |

`scripts\ci.ps1` 封装了：init/commit → 生成并打印 SSH 公钥 → 建仓库（有 token 时）→ push →
轮询 run → 下载 artifacts。没有 token 也能 push（建仓库需在网页端做一次）。

---

## 6. 执行阶段（已完成）

| 阶段 | 内容 | 结果 |
|---|---|---|
| P0 | 预检、状态快照、下载清单 | `state\pre-state.json`、`downloads.json` |
| P1 | 下载 + SHA-256 校验 + 解包 | Flutter 3.50.0 / Dart 3.14.0 |
| P2 | 环境变量、PATH、VS Code + 扩展 | `doctor` 全绿 |
| P3 | 示例工程（Flutter + SwiftUI + XcodeGen） | analyze 0 issue，6 个测试全过 |
| P4 | 本地预览与截图脚本 | 1179×2556 PNG，CDP 精确视口 |
| P5 | CI 工作流 + 静态检查 | Dart 校验器通过 |
| P6 | 端到端验证 | `04-verify.ps1`（见第 7 节） |
| P7 | 文档 + 回滚演练 | `-WhatIf` 逐条列出变更 |

---

## 7. 验收标准（可复核）

| # | 标准 | 复核方式 | 状态 |
|---|---|---|---|
| A1 | Flutter 3.50.0 / Dart 3.14.0 | `flutter --version` | ✅ |
| A2 | 无管理员改动；有快照 | `pre-state.json` + `admin=False` | ✅ |
| A3 | 格式 + 静态分析零问题 | `dart format` / `flutter analyze` | ✅ |
| A4 | 单元 + Widget 测试全绿 | `flutter test`（6 个） | ✅ |
| A5 | 本地 1179×2556 截图 | `ioslab.cmd shot` | ✅ |
| A6 | workflow 结构校验 | `validate_workflows.dart` | ✅ |
| A7 | CI 定义固定版本、可运行 | workflow 内容 + 首次 push | ✅ run #7 双 job 全绿（`macos-15-intel`，Xcode 16.4） |
| A8 | 回滚 `-WhatIf` 完整 | `09-uninstall.ps1 -WhatIf` | ✅ |

> **A7 已实跑通过**：<https://github.com/beschuvski/ioslab/actions/runs/43963522330>
> （2026-11-17 06:07 完成，两个 job 全绿）。`flutter-ios` 产物 49.8 MB（Simulator 亮/暗截图 +
> `.app` zip），`native-ios` 产物 5.9 MB（截图 + `.app` + `xcresult`）。
>
> 途中修复的两个真实问题，记录备查：
> 1. `.gitignore` 的 `*.xcodeproj/` 把 Flutter 的 `ios/Runner.xcodeproj` 也忽略了，macOS 上
>    `flutter build ios` 报 "Expected ios/Runner.xcodeproj but this file is missing" —— 已把
>    忽略规则收窄到 `apps/native_app/`，并提交 Flutter 的 Xcode 工程。
> 2. `ContentView.swift` 里 `withAnimation { model.runNextCheck() }` 返回 `Bool`，与 Button
>    action 的 `Void` 冲突（Xcode 报 "conflicting arguments to generic parameter 'Result'"）——
>    改为 `_ = model.runNextCheck()`。
>
> 另外，`.github/workflows/ios.yml` 现在会把构建失败的日志尾部写成 check-run annotation，
> 未认证也能通过 API 读到，排障不必依赖 token。

### 已完成的部分

GitHub 仓库 **`beschuvski/ioslab`** 已建好（public），SSH 公钥已注册，代码已推送
（`main`，含 4 个 commit）。`ci.ps1` 已验证可直接 push。

### 剩下的可选项

CI 已经全绿，代码、构建、模拟器、截图、产物都在跑。可选的后续：

1. **下载真实 Simulator 截图**：Actions → run #7 → Artifacts → `flutter-ios` / `native-ios`
   （命令行下载需要 `GITHUB_TOKEN`，未认证会 401）。
2. **Appetize 交互演示**：把 `ioslab-native-simulator.zip` 上传到 <https://appetize.io>。
3. **换 runner 池**：仓库 Settings → Variables 建 `IOS_RUNNER`（如 `macos-26`），无需改代码。

---

## 8. 风险与缓解

| 风险 | 影响 | 缓解 |
|---|---|---|
| `storage.googleapis.com` 不通 | 装不上 Flutter | 官方 CN 镜像 + 官方 SHA-256（实测 40 MB/s） |
| `github.com` 网页不通 | 无法用 gh/网页建仓 | 走 SSH + REST API；一次性配置在其它设备完成 |
| GitHub macOS runner 容量不足 | 排队约 15 分钟后被 cancelled（0 step） | 换池（`IOS_RUNNER` 变量）+ 稍后重试；或用 Codemagic/Bitrise 免费额度 |
| GitHub 发布资产 CDN 慢/断 | 装 gh、actionlint 失败 | 不装它们，用 git + Dart 校验器替代 |
| 非管理员 | 无法系统级安装 | 全用户态便携安装 |
| 8 GB 内存 | 本地并行构建慢 | 本地只跑 analyze/test/预览；重活给 CI |
| Windows MAX_PATH | pub/git 深层路径报错 | 短根目录 + `git config core.longpaths=true` |
| Xcode 27 设备名变化 | CI 脚本失败 | 动态发现模拟器 |
| Flutter 3.50 与 Xcode 27 兼容 | 构建失败 | 首次运行即验证；回退 `macos-15` |
| 免费 Appetize 3 分钟/会话 | 演示中断 | 仅验收演示用 |

---

## 9. 回滚（摘要）

1. 所有安装都在 `D:\iOSLab` + 3 个用户环境变量 + VS Code 用户安装，**无系统级改动**。
2. `state\pre-state.json` 保存改动前的 PATH、环境变量、已安装程序、关键路径存在性。
3. `ioslab.cmd uninstall`（即 `scripts\09-uninstall.ps1`）恢复环境变量 → 精确移除 PATH 条目
   → 卸载 VS Code 及扩展 → 撤销 git 全局配置 → 删除新增的用户级路径 → 删除 `D:\iOSLab`。
4. `-WhatIf` 可预演；实测回滚 < 3 分钟，无需重启。

详见 [`ROLLBACK.md`](ROLLBACK.md)。

---

## 10. 参考

- Flutter 支持平台（iOS 15–27）：<https://docs.flutter.dev/reference/supported-platforms>
- GitHub Actions macOS runner（macos-15 / macos-26；macOS 14 于 2026-11-02 退役）：
  <https://github.com/actions/runner-images>
- GitHub Actions 计费（公开仓库标准 runner 免费）：
  <https://docs.github.com/en/billing/concepts/product-billing/github-actions>
- Appetize 定价（Free：2 设备 / 30 分钟每月 / 单次 3 分钟）：<https://appetize.io/pricing>
- macOS 虚拟化许可边界：<https://expo.dev/articles/testing-and-previewing/test-ios-app-without-mac>
- XcodeGen：<https://github.com/yonaskolb/XcodeGen>
- Chrome DevTools Protocol（截图与设备模拟）：<https://chromedevtools.github.io/devtools-protocol/>




