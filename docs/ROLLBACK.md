# 回滚计划（Rollback Plan）

> 设计原则：**零系统级改动**。所有安装都在 `D:\iOSLab` 之内，加上 3 个用户环境变量、
> 1 个用户级 VS Code 安装、1 条 git 全局配置。没有服务、没有驱动、没有注册表关键项、
> 没有开机自启、没有防火墙规则。
>
> 回滚有两种方式：一键脚本（推荐）与手工步骤（脚本不可用时）。

---

## 1. 变更清单（Before → After → Rollback）

| # | 对象 | 变更 | 回滚动作 |
|---|---|---|---|
| 1 | `D:\iOSLab` | 新建（SDK、工具、工程、缓存、日志） | 删除目录；`-KeepProjects` 可保留 `projects\` |
| 2 | 用户环境变量 `PUB_CACHE` | 新增 = `D:\iOSLab\cache\pub` | 恢复快照值（原本不存在 → 删除） |
| 3 | 用户环境变量 `FLUTTER_STORAGE_BASE_URL` | 新增 = `https://storage.flutter-io.cn` | 恢复快照值 |
| 4 | 用户环境变量 `PUB_HOSTED_URL` | 新增 = `https://pub.flutter-io.cn` | 恢复快照值 |
| 5 | 用户 `PATH` | 追加 `D:\iOSLab\flutter\bin`、`D:\iOSLab\tools\git\cmd` | 精确删除这两条，保留其它条目 |
| 6 | VS Code（user setup） | 已安装 1.146.0 到 `%LOCALAPPDATA%\Programs\Microsoft VS Code`，并向用户 PATH 追加 `...\bin` 与 `...\bin\copilot-shim` 两条 | 静默卸载 → 删除残留目录 → 移除这两条 PATH 条目 |
| 7 | VS Code 扩展 | `Dart-Code.dart-code`、`Dart-Code.flutter` 写入 `%USERPROFILE%\.vscode\extensions` | 若该目录安装前不存在 → 整目录删除 |
| 8 | git 全局配置 | `core.longpaths`、`init.defaultBranch`、`core.quotepath`（写入 `%USERPROFILE%\.gitconfig`） | 若 `.gitconfig` 安装前不存在 → 删除文件；否则 `git config --global --unset-all` 这三个键 |
| 9 | `%USERPROFILE%\.flutter_settings` | Flutter 首次运行可能生成 | 仅当安装前不存在时删除 |
| 10 | `%LOCALAPPDATA%\Pub` | 若 `PUB_CACHE` 生效则不会出现；出现说明配置未生效 | 仅当安装前不存在时删除 |
| 11 | GitHub 仓库 / Secret | 仅在你执行 `ci.ps1` 并授权后产生（外部资源） | 删除仓库或在 GitHub 设置里删除 secret；本地无残留 |
| 12 | GitHub SSH 密钥 | `~\.ssh\id_ed25519`（仅在你运行 `ci.ps1` 时生成） | 先从 GitHub 删除该公钥，再删除本地密钥对 |

**不属于本方案的改动**：无人值守升级、系统服务、Hyper-V/WSL 开关、驱动、hosts 文件、
证书、防火墙、计划任务、开机启动项。因此回滚不涉及重启。

---

## 2. 回滚依据（快照）

`D:\iOSLab\state\pre-state.json`，在任何安装动作之前生成，包含：

- 用户 / 机器 / 进程级 `PATH`
- `PUB_CACHE`、`FLUTTER_STORAGE_BASE_URL`、`PUB_HOSTED_URL`、`FLUTTER_ROOT`、`DART_SDK`、
  `HTTP(S)_PROXY`、`NO_PROXY` 的用户/机器/进程三份取值
- OS 版本、硬件、是否管理员
- `winget list` 全量已安装程序（用于证明零新增）
- `fileMarkers`：`~\.flutter_settings`、`~\.dart-tool`、`~\.vscode`、`~\.gitconfig`、
  `%LOCALAPPDATA%\Pub`、`%LOCALAPPDATA%\Programs\Microsoft VS Code`、`%APPDATA%\Pub`、
  `%APPDATA%\dart`、`%APPDATA%\Code`、`%APPDATA%\GitHub CLI` 在安装前是否存在

---

## 3. 一键回滚

```powershell
# 1) 预演：只打印将要发生的变更，不动任何东西
D:\iOSLab\ioslab.cmd uninstall -WhatIf

# 2) 正式回滚（保留代码）
D:\iOSLab\ioslab.cmd uninstall -KeepProjects

# 3) 彻底回滚（连代码一起删）
D:\iOSLab\ioslab.cmd uninstall -Force
```

脚本行为（按顺序）：

1. 读取 `pre-state.json`；缺失则中止并提示手工步骤（防止"盲删"）。
2. 结束所有从 `D:\iOSLab` 启动的进程（`dart.exe`、`dartaotruntime.exe`、flutter 相关）。
3. 恢复 3 个环境变量为快照值（原本为空则删除）。
4. 从用户 `PATH` 中**逐条精确匹配**并移除本方案新增的条目；其它条目原样保留。
5. 若安装过 VS Code：运行其官方卸载器（`unins000.exe /VERYSILENT`），等待完成，
   删除残留目录。
6. 撤销 git 全局配置；若 `.gitconfig` 安装前不存在则删除该文件。
7. 对 `fileMarkers` 中"安装前不存在"的路径逐个删除（`.flutter_settings`、`.vscode` 等）。
8. 删除 `D:\iOSLab`；`-KeepProjects` / `-KeepCache` 可保留对应子目录。
9. 打印残留自检结果（PATH、环境变量、目录、VS Code 是否存在）。

> 脚本会把自己复制到 `%TEMP%` 后再执行删除动作，避免"删除正在运行的文件"失败。

---

## 4. 手工回滚（脚本丢失时）

```powershell
# 1. 用户环境变量：控制面板 → 系统 → 高级系统设置 → 环境变量（用户变量）
#    删除 PUB_CACHE / FLUTTER_STORAGE_BASE_URL / PUB_HOSTED_URL
#    编辑 Path，删除以下 3 条（若存在）：
#      D:\iOSLab\flutter\bin
#      D:\iOSLab\tools\git\cmd
#      %LOCALAPPDATA%\Programs\Microsoft VS Code\bin

# 2. 卸载 VS Code（若已装）
& "$env:LOCALAPPDATA\Programs\Microsoft VS Code\unins000.exe" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART

# 3. 删除残留目录
Remove-Item "$env:APPDATA\Code" -Recurse -Force            # 仅当安装前不存在
Remove-Item "$env:USERPROFILE\.vscode" -Recurse -Force     # 仅当安装前不存在
Remove-Item "$env:USERPROFILE\.flutter_settings" -Force    # 仅当安装前不存在
Remove-Item "$env:LOCALAPPDATA\Pub" -Recurse -Force        # 仅当安装前不存在

# 4. 删除本方案根目录（含 SDK、工具、缓存、工程、日志）
Remove-Item 'D:\iOSLab' -Recurse -Force
```

PATH 的修改也可以用快照文件逐字恢复：

```powershell
$s = Get-Content 'D:\iOSLab\state\pre-state.json' -Raw | ConvertFrom-Json
[Environment]::SetEnvironmentVariable('Path', $s.environment.Path.User, 'User')
```

---

## 5. 回滚后自检

| 检查 | 期望 |
|---|---|
| `flutter`、`dart`、`git`（系统无 git 时） | 全部 "not recognized" |
| `$env:PATH` 中 `iOSLab` | 0 处匹配 |
| `PUB_CACHE` / `FLUTTER_STORAGE_BASE_URL` / `PUB_HOSTED_URL` | 快照值（通常为空） |
| `Test-Path D:\iOSLab` | False（或仅剩 `projects\`，若用了 `-KeepProjects`） |
| `winget list` | 与 `pre-state.json` 的 `wingetPackages` 相比无新增 |
| VS Code | `%LOCALAPPDATA%\Programs\Microsoft VS Code` 不存在 |

---

## 6. 时间与影响

- 一键回滚实测耗时：**< 3 分钟**（主要耗在 VS Code 静默卸载）。
- 回滚不需要重启，不影响其它软件。
- 不可逆的部分只有：已消耗的 GitHub Actions 免费额度、Appetize 免费分钟数、
  以及你主动推送到 GitHub 的代码（需在 GitHub 侧删除仓库）。

---

## 7. 回滚触发条件

出现以下任一情况即执行回滚：

1. Flutter / VS Code 与现有软件冲突（杀软拦截、PATH 污染）。
2. 磁盘空间不足且短期无法扩容。
3. 安全审计要求移除第三方 SDK。
4. 迁移到 macOS 真机或远程 Mac，Windows 侧只保留编辑器。
