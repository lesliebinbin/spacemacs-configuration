# 浏览器本地 Chrome 远程调试钩子

**技能名称**: browser-local-chrome-remote-debugging  
**分类**: browser-automation  
**标签**: chrome, remote-debugging, websocket, cdp, browser-automation  
**难度**: intermediate  
**最后更新**: 2025-04-12  
**作者**: AI Agent

## 描述

此技能提供了一个钩子机制，拦截 `browser_navigate` 调用并将其透明地重定向到使用启用远程调试的本地 Chrome 实例。这种方法特别适用于：

- 具有复杂 JavaScript 交互的网站
- 检测并阻止无头浏览器的网站
- 需要视觉验证或截图分析的情况
- 调试浏览器自动化工作流程
- 提高与依赖特定 Chrome API 的网站的兼容性

该技能实现了优雅的回退机制：如果本地 Chrome 远程调试不可用或用户拒绝，它会无缝回退到标准的 `browser_navigate` 实现。

## 前提条件

- **操作系统**: Linux 或 macOS（Windows 支持需要适配）
- **Chrome 安装**: `google-chrome` 必须已安装并在 PATH 中
- **显示服务器**: X11（DISPLAY 环境变量，通常为 `:0`）
- **网络端口**: 端口 9232 可用（可配置）
- **Python 依赖**: `websockets`, `asyncio`（用于 WebSocket 通信）

## 详细步骤

### 1. 钩子触发与拦截

当 `browser_navigate` 被调用时：

1. **拦截调用**：在执行前拦截
2. **检查系统兼容性**：
   - 仅在 Linux/macOS 上继续
   - 在 Windows 上跳过（回退到标准 browser_navigate）
3. **验证 Chrome 安装**：
   ```python
   import shutil
   chrome_available = shutil.which("google-chrome") is not None
   ```

### 2. 用户确认和 Chrome 启动

如果系统检查通过：

4. **请求用户确认**以启动带远程调试的 Chrome：
   ```
   我将启动一个带远程调试的本地 Chrome 实例以获得更好的兼容性。
   
   允许我执行：
   google-chrome --remote-debugging-port=9232 \
     --user-data-dir=${HOME}/.chrome-remote-debugging \
     --remote-allow-origins='*'
   
   选项：
   1. 是的，启动带远程调试的 Chrome
   2. 不，使用标准的 browser_navigate
   ```

5. **如果用户选择"是"**：
   - 确保目录存在：`${HOME}/.chrome-remote-debugging`
   - 在后台启动 Chrome：
   ```bash
   google-chrome --remote-debugging-port=9232 \
     --user-data-dir=${HOME}/.chrome-remote-debugging \
     --remote-allow-origins='*' \
     --no-first-run \
     --no-default-browser-check \
     --disable-extensions \
     --disable-background-networking \
     --disable-sync \
     --disable-translate \
     --disable-default-apps \
     --disable-component-extensions-with-background-pages \
     --disable-component-update \
     --disable-breakpad \
     --disable-client-side-phishing-detection \
     --disable-crash-reporter \
     --disable-dev-shm-usage \
     --disable-popup-blocking \
     --disable-prompt-on-repost \
     --disable-renderer-backgrounding \
     --disable-background-timer-throttling \
     --disable-backgrounding-occluded-windows \
     --disable-ipc-flooding-protection \
     --disable-hang-monitor \
     --password-store=basic \
     --use-mock-keychain \
     --disable-features=TranslateUI,BlinkGenPropertyTrees \
     --enable-features=NetworkService,NetworkServiceInProcess \
     --headless=new \
     --hide-scrollbars \
     --mute-audio \
     --no-sandbox
   ```

   **修正的连接方法**：Chrome 输出的是 WebSocket 地址，不是 HTTP 端点：
   ```
   DevTools listening on ws://127.0.0.1:9232/devtools/browser/fb6a9d57-7c2b-495c-a0d4-06c6baccaffa
   ```

### 3. WebSocket 连接和浏览器控制

6. **通过 WebSocket 连接**（不是 HTTP/JSON）：
   ```python
   import asyncio
   import websockets
   import json
   
   async def connect_to_chrome():
       # 从 Chrome 输出中解析 WebSocket URL
       ws_url = "ws://127.0.0.1:9232/devtools/browser/fb6a9d57-7c2b-495c-a0d4-06c6baccaffa"
       
       async with websockets.connect(ws_url) as websocket:
           # 创建新标签页
           create_tab_cmd = {
               "id": 1,
               "method": "Target.createTarget",
               "params": {"url": "about:blank"}
           }
           await websocket.send(json.dumps(create_tab_cmd))
           response = await websocket.recv()
           tab_info = json.loads(response)
           
           # 连接到标签页的 DevTools
           tab_id = tab_info["result"]["targetId"]
           tab_ws_url = f"ws://127.0.0.1:9232/devtools/page/{tab_id}"
           
       return tab_ws_url
   ```

7. **导航到目标 URL**：
   ```python
   async def navigate_to_url(tab_ws_url, url):
       async with websockets.connect(tab_ws_url) as websocket:
           # 启用必要的域
           enable_cmds = [
               {"id": 2, "method": "Page.enable"},
               {"id": 3, "method": "Runtime.enable"},
               {"id": 4, "method": "Network.enable"},
               {"id": 5, "method": "DOM.enable"}
           ]
           
           for cmd in enable_cmds:
               await websocket.send(json.dumps(cmd))
               await websocket.recv()  # 等待响应
           
           # 导航
           navigate_cmd = {
               "id": 6,
               "method": "Page.navigate",
               "params": {"url": url}
           }
           await websocket.send(json.dumps(navigate_cmd))
           response = await websocket.recv()
           
           # 等待加载完成
           load_cmd = {
               "id": 7,
               "method": "Page.loadEventFired",
               "params": {}
           }
           await websocket.send(json.dumps(load_cmd))
           await websocket.recv()
   ```

### 4. 截图和 DOM 提取

8. **截取屏幕截图**：
   ```python
   async def take_screenshot(tab_ws_url):
       async with websockets.connect(tab_ws_url) as websocket:
           screenshot_cmd = {
               "id": 8,
               "method": "Page.captureScreenshot",
               "params": {"format": "png", "fromSurface": True}
           }
           await websocket.send(json.dumps(screenshot_cmd))
           response = await websocket.recv()
           result = json.loads(response)
           return result["result"]["data"]  # Base64 编码的 PNG
   ```

9. **获取 DOM 快照**：
   ```python
   async def get_dom_snapshot(tab_ws_url):
       async with websockets.connect(tab_ws_url) as websocket:
           # 获取文档根节点
           doc_cmd = {
               "id": 9,
               "method": "DOM.getDocument",
               "params": {"depth": -1, "pierce": True}
           }
           await websocket.send(json.dumps(doc_cmd))
           response = await websocket.recv()
           doc_info = json.loads(response)
           
           # 提取带引用 ID 的交互元素
           elements = extract_interactive_elements(doc_info)
           return format_snapshot(elements)  # 类似于 browser_snapshot 输出
   ```

### 5. 优雅回退实现

10. **错误处理和回退**：
    ```python
    def browser_navigate_hook(url):
        try:
            # 系统兼容性检查
            if not is_linux_macos():
                return standard_browser_navigate(url)
            
            # Chrome 可用性检查
            if not chrome_available():
                return standard_browser_navigate(url)
            
            # 用户确认
            if not ask_user_confirmation():
                return standard_browser_navigate(url)
            
            # 启动 Chrome 并通过 WebSocket 连接
            chrome_process = start_chrome_remote_debugging()
            tab_ws_url = connect_to_chrome_via_websocket()
            
            # 导航和交互
            asyncio.run(navigate_to_url(tab_ws_url, url))
            screenshot = asyncio.run(take_screenshot(tab_ws_url))
            snapshot = asyncio.run(get_dom_snapshot(tab_ws_url))
            
            return {
                "success": True,
                "snapshot": snapshot,
                "screenshot": screenshot,
                "method": "local_chrome_websocket"
            }
            
        except Exception as e:
            # 记录错误并回退
            log_error(f"本地 Chrome 钩子失败: {e}")
            return standard_browser_navigate(url)
        finally:
            # 清理 Chrome 进程
            if 'chrome_process' in locals():
                chrome_process.terminate()
    ```

## 实现示例

```python
import asyncio
import websockets
import json
import subprocess
import shutil
import os
from pathlib import Path

class ChromeRemoteDebuggingHook:
    def __init__(self, port=9232):
        self.port = port
        self.chrome_process = None
        self.ws_url = None
        
    def is_compatible(self):
        """检查系统是否支持本地 Chrome 远程调试。"""
        # 平台检查
        import platform
        system = platform.system().lower()
        if system not in ['linux', 'darwin']:
            return False
            
        # Chrome 可用性检查
        if shutil.which("google-chrome") is None:
            return False
            
        # 显示检查（对于 X11）
        if 'DISPLAY' not in os.environ:
            return False
            
        return True
    
    def start_chrome(self):
        """启动启用远程调试的 Chrome。"""
        user_data_dir = Path.home() / ".chrome-remote-debugging"
        user_data_dir.mkdir(exist_ok=True)
        
        cmd = [
            "google-chrome",
            f"--remote-debugging-port={self.port}",
            f"--user-data-dir={user_data_dir}",
            "--remote-allow-origins=*",
            "--no-first-run",
            "--no-default-browser-check",
            "--headless=new",
            "--disable-extensions",
            "--disable-gpu",
            "--no-sandbox"
        ]
        
        self.chrome_process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        # 等待 WebSocket URL 出现在 stderr 中
        for line in iter(self.chrome_process.stderr.readline, ''):
            if "DevTools listening on ws://" in line:
                self.ws_url = line.strip().split(" ")[-1]
                break
        
        return self.ws_url is not None
    
    async def navigate(self, url):
        """使用 Chrome DevTools Protocol 导航到 URL。"""
        if not self.ws_url:
            raise ValueError("Chrome 未启动或 WebSocket URL 不可用")
        
        # 连接到浏览器 WebSocket
        async with websockets.connect(self.ws_url) as ws:
            # 创建新标签页
            create_tab = {
                "id": 1,
                "method": "Target.createTarget",
                "params": {"url": "about:blank"}
            }
            await ws.send(json.dumps(create_tab))
            response = await ws.recv()
            tab_info = json.loads(response)
            tab_id = tab_info["result"]["targetId"]
            
            # 连接到标签页的 DevTools
            tab_ws_url = f"ws://127.0.0.1:{self.port}/devtools/page/{tab_id}"
            
        # 在标签页中导航
        async with websockets.connect(tab_ws_url) as ws:
            # 启用 Page 域
            await ws.send(json.dumps({"id": 2, "method": "Page.enable"}))
            await ws.recv()
            
            # 导航
            navigate_cmd = {
                "id": 3,
                "method": "Page.navigate",
                "params": {"url": url}
            }
            await ws.send(json.dumps(navigate_cmd))
            response = await ws.recv()
            
            # 等待加载
            load_event = await ws.recv()
            
            # 截取屏幕截图
            screenshot_cmd = {
                "id": 4,
                "method": "Page.captureScreenshot",
                "params": {"format": "png"}
            }
            await ws.send(json.dumps(screenshot_cmd))
            screenshot_response = await ws.recv()
            
            return json.loads(screenshot_response)
    
    def cleanup(self):
        """清理 Chrome 进程。"""
        if self.chrome_process:
            self.chrome_process.terminate()
            self.chrome_process.wait()
```

## 故障排除

### 常见问题

1. **WebSocket 连接被拒绝**：
   - 验证 Chrome 是否成功启动：检查 stderr 中的 WebSocket URL
   - 确保端口未被阻塞：`netstat -tlnp | grep 9232`
   - 检查 Chrome 进程是否正在运行：`ps aux | grep chrome`

2. **Chrome 启动失败**：
   - 检查 DISPLAY 环境变量：`echo $DISPLAY`
   - 验证 Chrome 安装：`google-chrome --version`
   - 如果 9232 端口被占用，尝试不同的端口

3. **缺少依赖项**：
   - 安装 websockets：`pip install websockets`
   - 确保 asyncio 可用（Python 3.7+）

4. **权限问题**：
   - Chrome 用户数据目录必须可写
   - 端口必须可访问（非特权端口 > 1024）

### 调试步骤

1. **手动测试 Chrome 启动**：
   ```bash
   google-chrome --remote-debugging-port=9232 --user-data-dir=/tmp/chrome-test --remote-allow-origins='*' --headless=new
   ```

2. **验证 WebSocket 连接**：
   ```python
   import asyncio
   import websockets
   
   async def test_connection():
       try:
           async with websockets.connect("ws://127.0.0.1:9232/json") as ws:
               print("连接成功")
       except Exception as e:
           print(f"连接失败: {e}")
   
   asyncio.run(test_connection())
   ```

3. **检查 Chrome DevTools Protocol**：
   - 在浏览器中访问 `http://localhost:9232/json`（用于调试信息）
   - 这会返回包含每个目标的 WebSocket URL 的 JSON

## 安全考虑

1. **隔离的用户数据**：每个会话使用单独的 `--user-data-dir` 以防止配置文件污染
2. **端口绑定**：Chrome 仅绑定到 localhost（127.0.0.1），而不是所有接口
3. **源限制**：`--remote-allow-origins='*'` 允许任何源；如果需要可以限制
4. **进程隔离**：Chrome 在单独的进程中运行，会话结束后终止
5. **无头模式**：默认为无头模式以提高安全性；调试时如果需要可以禁用

## 性能注意事项

1. **Chrome 启动开销**：初始启动约 2-3 秒
2. **WebSocket 延迟**：本地连接延迟最小
3. **内存使用**：Chrome 进程使用 200-500MB RAM
4. **连接池**：尽可能为多次导航重用 Chrome 实例

## 与 AI 代理的集成

### 对于 Hermes-Agent：

1. **添加到 toolsets.py**：创建新工具集或扩展现有的浏览器工具集
2. **在 model_tools.py 中注册钩子**：拦截 browser_navigate 调用
3. **用户配置**：添加到 `~/.hermes/config.yaml`：
   ```yaml
   browser:
     use_local_chrome: true
     chrome_port: 9232
     ask_confirmation: true
   ```

### 对于 OpenClaw：

1. **扩展浏览器自动化模块**：添加 Chrome CDP 集成
2. **配置选项**：环境变量或配置文件
3. **回退策略**：确保与现有浏览器工具的兼容性

## 参考文献

1. **Chrome DevTools Protocol**: https://chromedevtools.github.io/devtools-protocol/
2. **WebSocket API**: https://websockets.readthedocs.io/
3. **Headless Chrome**: https://developer.chrome.com/docs/chromium/new-headless
4. **Remote Debugging Guide**: https://developer.chrome.com/docs/devtools/remote-debugging/

## 更新日志

- **2025-04-12**: 带有 WebSocket 修正的初始版本
- **关键修正**：将连接方法从 HTTP/JSON 修正为 WebSocket 协议
- **新增**：从 Chrome 输出中正确解析 WebSocket URL
- **增强**：异步 WebSocket 通信示例
- **改进**：错误处理和清理程序