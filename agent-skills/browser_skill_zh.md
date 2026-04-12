# 浏览器导航与 Chrome 远程调试钩子

## 描述
本技能为 `browser_navigate` 工具提供了一个钩子（hook），首先检查系统是否可以使用启用远程调试的本地 Chrome 实例。如果条件满足且用户同意，则启动带有远程调试的 Chrome，并允许后续的浏览器交互连接到该实例。否则，回退到默认的 `browser_navigate` 行为。

## 目的
通过使用带有完整 Chrome DevTools Protocol 的本地 Chrome 实例，提高浏览器自动化的可靠性，特别是对于屏蔽无头浏览器或需要复杂交互的网站。

## 前置条件
- Linux 或 macOS 操作系统（Windows 上跳过此钩子）
- 已安装 Google Chrome 并在 PATH 中可用（命令为 `google-chrome`）
- 用户允许使用远程调试标志启动 Chrome

## 技能逻辑流程

### 步骤 1：钩子拦截
当 `browser_navigate` 即将被调用时，在工具运行之前拦截执行。

### 步骤 2：操作系统检查
- 检查当前操作系统是否为 Linux 或 macOS
- 如果不是，跳过钩子，执行原始的 `browser_navigate`
- 检测方法：`uname -s` 或 Python 的 `platform.system()`

### 步骤 3：Chrome 可用性检查
- 检查是否安装了 `google-chrome` 并在 PATH 中可用
- 使用 `which google-chrome` 或类似命令
- 如果未找到，跳过钩子，执行原始的 `browser_navigate`

### 步骤 4：用户确认
询问用户是否要启动带有远程调试的 Chrome：
```
我可以使用带有远程调试的本地 Chrome 实例以获得更好的浏览器自动化效果。
您希望我运行以下命令吗：
  google-chrome --remote-debugging-port=9232 --user-data-dir=${HOME}/.chrome-remote-debugging --remote-allow-origins='*'
  
选项：
1. 是，启动 Chrome 并使用远程调试
2. 否，使用默认的 browser_navigate 工具
```

### 步骤 5：目录准备
如果用户选择“是”：
- 确保 `${HOME}/.chrome-remote-debugging` 目录存在
- 必要时创建：`mkdir -p "${HOME}/.chrome-remote-debugging"`

### 步骤 6：Chrome 启动
执行命令：
```bash
google-chrome --remote-debugging-port=9232 --user-data-dir="${HOME}/.chrome-remote-debugging" --remote-allow-origins='*'
```
注意：Chrome 可能已经在运行。该命令可能启动新实例或重用现有实例。

### 步骤 7：连接与导航
Chrome 启动（或确认运行）后：
1. 等待几秒钟让 Chrome 启动（3-5 秒）
2. 使用 Chrome DevTools Protocol 连接到远程调试端口（9232）
3. 创建新标签页或使用现有标签页导航到目标 URL
4. 将控制权交还给浏览器自动化工具

### 步骤 8：回退
如果用户选择“否”或任何步骤失败：
- 正常执行原始的 `browser_navigate` 工具
- 本次会话不再进行拦截

## 实现注意事项

### 检测命令
```bash
# 检查操作系统
uname -s  # 返回 "Linux", "Darwin" 等

# 检查 Chrome 安装
which google-chrome
google-chrome --version
```

### Chrome 命令详情
- 端口：9232（选择可用端口，避免冲突）
- 用户数据目录：独立配置文件，避免干扰用户的主 Chrome
- 远程允许来源：'*' 允许来自任何来源的连接（为开发安全考虑）

### 安全考虑
1. 远程调试端口应仅绑定到 localhost（默认行为）
2. 使用独立的用户数据目录以防止数据混合
3. 如果 Chrome 在 30 秒内未启动，钩子应超时
4. 清理：会话结束后提供关闭 Chrome 的选项，或保持运行以供将来使用

### 与 AI 代理集成（OpenClaw, Hermes-Agent）
1. 此技能应在任何浏览器自动化任务之前加载
2. 钩子应该是透明的 - 如果失败，代理应继续使用默认工具
3. 代理应知道如何在 Chrome 启动后连接到 Chrome DevTools Protocol (CDP)

## 使用示例

```python
# 钩子的伪代码
def browser_navigate_hook(url):
    if not is_linux_or_macos():
        return default_browser_navigate(url)
    
    if not chrome_installed():
        return default_browser_navigate(url)
    
    response = ask_user("是否启动带有远程调试的 Chrome？")
    if response != "yes":
        return default_browser_navigate(url)
    
    ensure_directory_exists("${HOME}/.chrome-remote-debugging")
    launch_chrome_remote_debugging()
    
    # 通过 CDP 连接并导航
    return navigate_via_cdp(url)
```

## 故障排除

### 常见问题
1. **端口已被占用**：尝试不同的端口（例如 9233、9234）
2. **Chrome 无法启动**：检查现有的 Chrome 进程，必要时结束它们
3. **连接被拒绝**：确保 Chrome 成功启动，等待更长时间
4. **权限被拒绝**：用户数据目录可能具有错误的权限

### 调试步骤
1. 检查 Chrome 是否运行：`ps aux | grep chrome`
2. 测试端口连接性：`curl http://localhost:9232/json`
3. 验证目录是否存在且权限正确
4. 检查 Chrome 日志中的错误

## 参考
- Chrome DevTools Protocol: https://chromedevtools.github.io/devtools-protocol/
- Chrome 命令行开关: https://peter.sh/experiments/chromium-command-line-switches/
- 远程调试文档: https://developer.chrome.com/docs/devtools/remote-debugging/

---
**技能名称**: browser-chrome-remote-hook  
**类别**: browser-automation  
**标签**: chrome, remote-debugging, browser-navigation, hook  
**版本**: 1.0  
**作者**: Hermes Agent 社区  
**最后更新**: 2026-04-12