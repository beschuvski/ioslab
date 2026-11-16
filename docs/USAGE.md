# 使用手册（USAGE）

所有命令都从 `D:\iOSLab\ioslab.cmd` 进入，**不需要管理员权限**，也不需要改系统设置。

```bat
D:\iOSLab\ioslab.cmd check
D:\iOSLab\ioslab.cmd preview
D:\iOSLab\ioslab.cmd shot
D:\iOSLab\ioslab.cmd doctor
D:\iOSLab\ioslab.cmd verify
D:\iOSLab\ioslab.cmd ci -Name <owner>/<repo>
D:\iOSLab\ioslab.cmd uninstall -WhatIf
```

---

## 1. 一分钟上手

```bat
:: 1) 质量门禁：格式化 + 分析 + 测试
D:\iOSLab\ioslab.cmd check

:: 2) 本地 iPhone 视口预览（热重载，Edge 无边框窗口）
D:\iOSLab\ioslab.cmd preview
::    停止：D:\iOSLab\ioslab.cmd preview -Stop

:: 3) 截图（1179 x 2556，iPhone 16/17 像素）
D:\iOSLab\ioslab.cmd shot
::    产物：D:\iOSLab\projects\ioslab\artifacts\screenshots\local.png
```

代码位置：

- Flutter 应用：`D:\iOSLab\projects\ioslab\apps\flutter_app`
- SwiftUI 原生示例：`D:\iOSLab\projects\ioslab\apps\native_app`
- CI 流水线：`D:\iOSLab\projects\ioslab\.github\workflows\ios.yml`

---

## 2. 命令说明

| 命令 | 作用 | 备注 |
|---|---|---|
| `check` | `dart format --set-exit-if-changed` + `flutter analyze --fatal-infos` + `flutter test` | 与 CI 同门槛 |
| `preview` | `flutter run -d web-server` + Edge `--app` 窗口 | 支持热重载；窗口默认 393×852 |
| `preview -Stop` | 停止后台 web-server | 进程记录在 `state\preview.pid` |
| `shot` | release web 构建 + CDP 精确设备模拟截图 | 参数 `-Name`、`-Out`、`-SkipBuild` |
| `doctor` | 系统 / 工具链 / 环境变量 / 项目 / flutter doctor 摘要 | 排障第一站 |
| `verify` | 端到端自检 A1–A8，写 `state\verify-report.json` | 可加 `-SkipShot` |
| `ci` | 初始化仓库、打印 SSH 公钥、push、轮询 CI、下载产物 | 见第 4 节 |
| `uninstall` | 回滚安装 | 先跑 `-WhatIf` |

---

## 3. 日常开发流程

```text
编辑（VS Code）
   ↓
ioslab.cmd check            ← 秒级反馈，失败不提交
   ↓
ioslab.cmd preview          ← 看布局 / 交互，热重载
   ↓
ioslab.cmd shot             ← 截图贴 PR / 设计走查
   ↓
git commit && ioslab.cmd ci ← 云端真机（Simulator）验证
```

### 在编辑器里打开

```bat
code D:\iOSLab\projects\ioslab
```

已安装 **VS Code 1.146.0**（用户级），扩展 `dart-code.dart-code`、`dart-code.flutter`
已装，用户设置已把 Flutter SDK 指向 `D:\iOSLab\flutter`，保存即格式化。
仓库里还有 `.vscode/settings.json` 与 `extensions.json`，换机器也能保持一致。

> 若以后需要重装/升级：`powershell -NoProfile -ExecutionPolicy Bypass -File D:\iOSLab\scripts\03-vscode.ps1`
> （脚本带 `curl -C -` 断点续传与 Authenticode 签名校验，可反复执行）。

### 本地截图能代替 iOS Simulator 吗

不能完全代替，但很接近：视口、DPR、字体渲染路径与浏览器一致，适合布局走查；
**最终以 CI 里真实 iOS Simulator 的截图为依据**（`artifacts/screenshots/*-light.png`、
`*-dark.png`）。差异点：Web 用浏览器字体，iOS 用系统字体（SF），且没有 iOS 原生控件。

---

## 4. 首次接入 GitHub / CI

本机网络下 `github.com` 网页不可达，但 `api.github.com` 与 `ssh://git@github.com` 可用。

```bat
:: 1) 仅准备：初始化仓库、提交、生成并打印 SSH 公钥
D:\iOSLab\ioslab.cmd ci -Name <你的账号>/ioslab -PrepareOnly
```

把打印出来的公钥加到 GitHub（Settings → SSH and GPG keys）。

```bat
:: 2) 如果仓库还不存在：在网页端建一个空仓库，或提供 token 让脚本代建
set GITHUB_TOKEN=ghp_xxx
D:\iOSLab\ioslab.cmd ci -Name <你的账号>/ioslab -Watch
```

`-Watch` 会：push → 等 workflow → 打印两个 job 的结论 → 下载产物到
`projects\ioslab\artifacts\ci\`。

> Token 需要 `repo` 与 `workflow` 权限。没有 token 时 `ci` 只做 push，
> 运行结果在 `https://github.com/<owner>/<repo>/actions` 查看（可在其它设备打开）。

### 交互式 iOS 模拟器（可选）

1. 从 CI 产物下载 `ioslab-native-simulator.zip`（内含 `NativeLab.app`）；
2. 打开 <https://appetize.io>，上传 zip，选择 iPhone 机型；
3. 浏览器里即可点按运行（免费额度 30 分钟/月，单次会话 3 分钟）。

若配置了 `APPETIZE_API_KEY` secret，可在 Actions 页面手动触发并勾选 `appetize` 自动上传。

---

## 5. 目录与日志

| 路径 | 内容 |
|---|---|
| `D:\iOSLab\logs\` | `01-download.log`、`02-install.log`、`03-vscode.log`、`preview.log`、`serve-web.log` |
| `D:\iOSLab\state\pre-state.json` | 安装前快照（回滚依据） |
| `D:\iOSLab\state\downloads.json` | 下载清单与哈希 |
| `D:\iOSLab\state\verify-report.json` | 最近一次自检结果 |
| `D:\iOSLab\cache\pub\` | pub 缓存（可随时删除） |

---

## 6. 常见问题

**`flutter` 不是内部或外部命令**
新开的终端才会读到用户 PATH。或直接用 `D:\iOSLab\ioslab.cmd`，它自己注入环境。

**`ioslab.cmd` 报"禁止运行脚本"**
入口已经用 `-ExecutionPolicy Bypass` 调用 PowerShell，请确认是从 `ioslab.cmd` 进入，
而不是直接右键运行 `.ps1`。

**预览窗口比 393 宽**
Chromium 对普通窗口有最小宽度限制（实测约 482 px）。需要精确像素时用 `shot`（CDP 强制 393）。

**`shot` 很慢**
第一次要 `flutter build web --release`（约 60–90 秒）；之后增量构建约 10–20 秒。

**Web 预览字体和 iPhone 不一样**
浏览器没有 SF 字体，Flutter 会回退到系统字体。布局一致，字形不同。

**`flutter analyze` 报 cupertino 相关 deprecation**
Flutter 3.50 起 Cupertino 拆到 `package:cupertino_ui/cupertino_ui.dart`；
本工程已按新包导入，`pubspec.yaml` 里固定了 `cupertino_ui: ^1.1.6`。

**CI 上 iOS 构建失败**
先看 `flutter-ios` job 里 `Build for iOS Simulator` 步骤；常见原因是依赖需要 CocoaPods
或 Xcode 版本更新。把 `ios.yml` 的 `runs-on` 换成 `macos-15` / `macos-26` 可换池重试。

**CI 一直 queued，约 15 分钟后变成 cancelled、0 个 step**
这是 GitHub 托管 macOS runner 的**容量问题**，不是代码或配置错误：arm64 池在高峰时段经常
分配不到机器，GitHub 等约 15 分钟后放弃并 cancel，annotation 为
"The job was not acquired by Runner of type hosted"。这不是 `timeout-minutes`，也无法通过
改 workflow 延长。处理办法：

1. 直接 `git commit --allow-empty -m retry` 再推一次，换个时间点重试；
2. 换池：把 `runs-on` 改成 `macos-15-intel`（Intel，默认值）或 `macos-15` / `macos-26`（arm64）；
3. 在仓库 Settings → Variables 里建 `IOS_RUNNER`，以后不改代码就能换池；
4. 持续失败的话，用 Codemagic / Bitrise 的免费额度，或自托管 Mac runner。

参考社区同类报告：<https://github.com/orgs/community/discussions/212075>、
<https://github.com/orgs/community/discussions/211885>。

---

## 7. 升级

```bat
:: Flutter
D:\iOSLab\flutter\bin\flutter.bat upgrade

:: 然后同步 CI 的固定版本
:: .github/workflows/ios.yml -> env.FLUTTER_VERSION
```

升级后跑一遍 `ioslab.cmd verify`。

---

## 8. 卸载

```bat
D:\iOSLab\ioslab.cmd uninstall -WhatIf      :: 预演
D:\iOSLab\ioslab.cmd uninstall -KeepProjects :: 保留代码，删除工具链
D:\iOSLab\ioslab.cmd uninstall -Force        :: 全部删除
```

详见 [`ROLLBACK.md`](ROLLBACK.md)。
