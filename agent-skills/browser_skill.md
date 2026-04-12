# Browser Local Chrome Remote Debugging Hook

**Skill Name**: browser-local-chrome-remote-debugging  
**Category**: browser-automation  
**Tags**: chrome, remote-debugging, websocket, cdp, browser-automation  
**Difficulty**: intermediate  
**Last Updated**: 2025-04-12  
**Author**: AI Agent

## Description

This skill provides a hook mechanism that intercepts `browser_navigate` calls and transparently redirects them to use a locally running Chrome instance with remote debugging enabled. This approach is particularly useful for:

- Complex websites with JavaScript-heavy interactions
- Sites that detect and block headless browsers
- Situations where visual verification or screenshot analysis is needed
- Debugging browser automation workflows
- Improving compatibility with sites that rely on specific Chrome APIs

The skill implements a graceful fallback: if local Chrome remote debugging is unavailable or the user declines, it seamlessly falls back to the standard `browser_navigate` implementation.

## Prerequisites

- **Operating System**: Linux or macOS (Windows support requires adaptation)
- **Chrome Installation**: `google-chrome` must be installed and in PATH
- **Display Server**: X11 (DISPLAY environment variable, typically `:0`)
- **Network Port**: Port 9232 available (configurable)
- **Python Dependencies**: `websockets`, `asyncio` (for WebSocket communication)

## Detailed Steps

### 1. Hook Trigger and Interception

When `browser_navigate` is called:

1. **Intercept the call** before execution
2. **Check system compatibility**:
   - Only proceed on Linux/macOS
   - Skip on Windows (fallback to standard browser_navigate)
3. **Verify Chrome installation**:
   ```python
   import shutil
   chrome_available = shutil.which("google-chrome") is not None
   ```

### 2. User Confirmation and Chrome Startup

If system checks pass:

4. **Ask user for permission** to start Chrome with remote debugging:
   ```
   I'll start a local Chrome instance with remote debugging for better compatibility.
   
   Allow me to execute:
   google-chrome --remote-debugging-port=9232 \
     --user-data-dir=${HOME}/.chrome-remote-debugging \
     --remote-allow-origins='*'
   
   Options:
   1. Yes, start Chrome with remote debugging
   2. No, use standard browser_navigate
   ```

5. **If user selects "Yes"**:
   - Ensure directory exists: `${HOME}/.chrome-remote-debugging`
   - Start Chrome in background:
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

   **CORRECTED CONNECTION APPROACH**: Chrome outputs WebSocket address, not HTTP endpoint:
   ```
   DevTools listening on ws://127.0.0.1:9232/devtools/browser/fb6a9d57-7c2b-495c-a0d4-06c6baccaffa
   ```

### 3. WebSocket Connection and Browser Control

6. **Connect via WebSocket** (not HTTP/JSON):
   ```python
   import asyncio
   import websockets
   import json
   
   async def connect_to_chrome():
       # Parse WebSocket URL from Chrome output
       ws_url = "ws://127.0.0.1:9232/devtools/browser/fb6a9d57-7c2b-495c-a0d4-06c6baccaffa"
       
       async with websockets.connect(ws_url) as websocket:
           # Create a new tab
           create_tab_cmd = {
               "id": 1,
               "method": "Target.createTarget",
               "params": {"url": "about:blank"}
           }
           await websocket.send(json.dumps(create_tab_cmd))
           response = await websocket.recv()
           tab_info = json.loads(response)
           
           # Connect to the tab's DevTools
           tab_id = tab_info["result"]["targetId"]
           tab_ws_url = f"ws://127.0.0.1:9232/devtools/page/{tab_id}"
           
       return tab_ws_url
   ```

7. **Navigate to target URL**:
   ```python
   async def navigate_to_url(tab_ws_url, url):
       async with websockets.connect(tab_ws_url) as websocket:
           # Enable necessary domains
           enable_cmds = [
               {"id": 2, "method": "Page.enable"},
               {"id": 3, "method": "Runtime.enable"},
               {"id": 4, "method": "Network.enable"},
               {"id": 5, "method": "DOM.enable"}
           ]
           
           for cmd in enable_cmds:
               await websocket.send(json.dumps(cmd))
               await websocket.recv()  # Wait for response
           
           # Navigate
           navigate_cmd = {
               "id": 6,
               "method": "Page.navigate",
               "params": {"url": url}
           }
           await websocket.send(json.dumps(navigate_cmd))
           response = await websocket.recv()
           
           # Wait for load complete
           load_cmd = {
               "id": 7,
               "method": "Page.loadEventFired",
               "params": {}
           }
           await websocket.send(json.dumps(load_cmd))
           await websocket.recv()
   ```

### 4. Screenshot and DOM Extraction

8. **Take screenshot**:
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
           return result["result"]["data"]  # Base64 encoded PNG
   ```

9. **Get DOM snapshot**:
   ```python
   async def get_dom_snapshot(tab_ws_url):
       async with websockets.connect(tab_ws_url) as websocket:
           # Get document root
           doc_cmd = {
               "id": 9,
               "method": "DOM.getDocument",
               "params": {"depth": -1, "pierce": True}
           }
           await websocket.send(json.dumps(doc_cmd))
           response = await websocket.recv()
           doc_info = json.loads(response)
           
           # Extract interactive elements with ref IDs
           elements = extract_interactive_elements(doc_info)
           return format_snapshot(elements)  # Similar to browser_snapshot output
   ```

### 5. Graceful Fallback Implementation

10. **Error handling and fallback**:
    ```python
    def browser_navigate_hook(url):
        try:
            # System compatibility check
            if not is_linux_macos():
                return standard_browser_navigate(url)
            
            # Chrome availability check
            if not chrome_available():
                return standard_browser_navigate(url)
            
            # User confirmation
            if not ask_user_confirmation():
                return standard_browser_navigate(url)
            
            # Start Chrome and connect via WebSocket
            chrome_process = start_chrome_remote_debugging()
            tab_ws_url = connect_to_chrome_via_websocket()
            
            # Navigate and interact
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
            # Log error and fallback
            log_error(f"Local Chrome hook failed: {e}")
            return standard_browser_navigate(url)
        finally:
            # Clean up Chrome process
            if 'chrome_process' in locals():
                chrome_process.terminate()
    ```

## Implementation Example

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
        """Check if system supports local Chrome remote debugging."""
        # Platform check
        import platform
        system = platform.system().lower()
        if system not in ['linux', 'darwin']:
            return False
            
        # Chrome availability
        if shutil.which("google-chrome") is None:
            return False
            
        # Display check (for X11)
        if 'DISPLAY' not in os.environ:
            return False
            
        return True
    
    def start_chrome(self):
        """Start Chrome with remote debugging enabled."""
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
        
        # Wait for WebSocket URL to appear in stderr
        for line in iter(self.chrome_process.stderr.readline, ''):
            if "DevTools listening on ws://" in line:
                self.ws_url = line.strip().split(" ")[-1]
                break
        
        return self.ws_url is not None
    
    async def navigate(self, url):
        """Navigate to URL using Chrome DevTools Protocol."""
        if not self.ws_url:
            raise ValueError("Chrome not started or WebSocket URL not available")
        
        # Connect to browser WebSocket
        async with websockets.connect(self.ws_url) as ws:
            # Create new tab
            create_tab = {
                "id": 1,
                "method": "Target.createTarget",
                "params": {"url": "about:blank"}
            }
            await ws.send(json.dumps(create_tab))
            response = await ws.recv()
            tab_info = json.loads(response)
            tab_id = tab_info["result"]["targetId"]
            
            # Connect to tab's DevTools
            tab_ws_url = f"ws://127.0.0.1:{self.port}/devtools/page/{tab_id}"
            
        # Navigate in the tab
        async with websockets.connect(tab_ws_url) as ws:
            # Enable Page domain
            await ws.send(json.dumps({"id": 2, "method": "Page.enable"}))
            await ws.recv()
            
            # Navigate
            navigate_cmd = {
                "id": 3,
                "method": "Page.navigate",
                "params": {"url": url}
            }
            await ws.send(json.dumps(navigate_cmd))
            response = await ws.recv()
            
            # Wait for load
            load_event = await ws.recv()
            
            # Take screenshot
            screenshot_cmd = {
                "id": 4,
                "method": "Page.captureScreenshot",
                "params": {"format": "png"}
            }
            await ws.send(json.dumps(screenshot_cmd))
            screenshot_response = await ws.recv()
            
            return json.loads(screenshot_response)
    
    def cleanup(self):
        """Clean up Chrome process."""
        if self.chrome_process:
            self.chrome_process.terminate()
            self.chrome_process.wait()
```

## Troubleshooting

### Common Issues

1. **WebSocket connection refused**:
   - Verify Chrome started successfully: check stderr for WebSocket URL
   - Ensure port is not blocked: `netstat -tlnp | grep 9232`
   - Check Chrome process is running: `ps aux | grep chrome`

2. **Chrome fails to start**:
   - Check DISPLAY environment variable: `echo $DISPLAY`
   - Verify Chrome installation: `google-chrome --version`
   - Try different port if 9232 is occupied

3. **Missing dependencies**:
   - Install websockets: `pip install websockets`
   - Ensure asyncio is available (Python 3.7+)

4. **Permission issues**:
   - Chrome user data directory must be writable
   - Port must be accessible (non-privileged ports > 1024)

### Debugging Steps

1. **Test Chrome startup manually**:
   ```bash
   google-chrome --remote-debugging-port=9232 --user-data-dir=/tmp/chrome-test --remote-allow-origins='*' --headless=new
   ```

2. **Verify WebSocket connection**:
   ```python
   import asyncio
   import websockets
   
   async def test_connection():
       try:
           async with websockets.connect("ws://127.0.0.1:9232/json") as ws:
               print("Connected successfully")
       except Exception as e:
           print(f"Connection failed: {e}")
   
   asyncio.run(test_connection())
   ```

3. **Check Chrome DevTools Protocol**:
   - Visit `http://localhost:9232/json` in browser (for debugging info)
   - This returns JSON with WebSocket URLs for each target

## Security Considerations

1. **Isolated user data**: Each session uses separate `--user-data-dir` to prevent profile contamination
2. **Port binding**: Chrome binds to localhost only (127.0.0.1), not all interfaces
3. **Origin restrictions**: `--remote-allow-origins='*'` allows any origin; restrict if needed
4. **Process isolation**: Chrome runs in separate process, terminated after session
5. **Headless mode**: Defaults to headless for security; disable for debugging if needed

## Performance Notes

1. **Chrome startup overhead**: ~2-3 seconds for initial launch
2. **WebSocket latency**: Minimal for local connections
3. **Memory usage**: Chrome process uses 200-500MB RAM
4. **Connection pooling**: Reuse Chrome instance for multiple navigations when possible

## Integration with AI Agents

### For Hermes-Agent:

1. **Add to toolsets.py**: Create new toolset or extend existing browser toolset
2. **Register hook in model_tools.py**: Intercept browser_navigate calls
3. **User configuration**: Add to `~/.hermes/config.yaml`:
   ```yaml
   browser:
     use_local_chrome: true
     chrome_port: 9232
     ask_confirmation: true
   ```

### For OpenClaw:

1. **Extend browser automation module**: Add Chrome CDP integration
2. **Configuration options**: Environment variables or config file
3. **Fallback strategy**: Ensure compatibility with existing browser tools

## References

1. **Chrome DevTools Protocol**: https://chromedevtools.github.io/devtools-protocol/
2. **WebSocket API**: https://websockets.readthedocs.io/
3. **Headless Chrome**: https://developer.chrome.com/docs/chromium/new-headless
4. **Remote Debugging Guide**: https://developer.chrome.com/docs/devtools/remote-debugging/

## Changelog

- **2025-04-12**: Initial version with WebSocket correction
- **Key Correction**: Fixed connection method from HTTP/JSON to WebSocket protocol
- **Added**: Proper WebSocket URL parsing from Chrome output
- **Enhanced**: Asynchronous WebSocket communication examples
- **Improved**: Error handling and cleanup procedures