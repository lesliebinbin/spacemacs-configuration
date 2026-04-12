# Browser Navigation with Chrome Remote Debugging Hook

## Description
This skill provides a hook for the `browser_navigate` tool that first checks if the system can use a locally running Chrome instance with remote debugging enabled. If conditions are met and the user approves, it launches Chrome with remote debugging and allows subsequent browser interactions to connect to it. Otherwise, it falls back to the default `browser_navigate` behavior.

## Purpose
Improve browser automation reliability by using a local Chrome instance with the full Chrome DevTools Protocol, especially for sites that block headless browsers or require complex interactions.

## Prerequisites
- Linux or macOS operating system (the hook skips on Windows)
- Google Chrome installed and available in PATH as `google-chrome`
- User permission to launch Chrome with remote debugging flags

## Skill Logic Flow

### Step 1: Hook Interception
When `browser_navigate` is about to be called, intercept the execution before the tool runs.

### Step 2: OS Check
- Check if the current OS is Linux or macOS
- If not, skip the hook and execute the original `browser_navigate`
- Detection method: `uname -s` or platform.system() in Python

### Step 3: Chrome Availability Check
- Check if `google-chrome` is installed and available in PATH
- Use `which google-chrome` or similar command
- If not found, skip the hook and execute the original `browser_navigate`

### Step 4: User Confirmation
Ask the user if they want to launch Chrome with remote debugging:
```
I can use a local Chrome instance with remote debugging for better browser automation.
Would you like me to run:
  google-chrome --remote-debugging-port=9232 --user-data-dir=${HOME}/.chrome-remote-debugging --remote-allow-origins='*'
  
Options:
1. Yes, launch Chrome and use remote debugging
2. No, use the default browser_navigate tool
```

### Step 5: Directory Preparation
If the user chooses "Yes":
- Ensure `${HOME}/.chrome-remote-debugging` directory exists
- Create it if necessary: `mkdir -p "${HOME}/.chrome-remote-debugging"`

### Step 6: Chrome Launch
Execute the command:
```bash
google-chrome --remote-debugging-port=9232 --user-data-dir="${HOME}/.chrome-remote-debugging" --remote-allow-origins='*'
```
Note: Chrome may already be running. The command might start a new instance or reuse an existing one.

### Step 7: Connection & Navigation
After Chrome is launched (or confirmed running):
1. Wait a few seconds for Chrome to start (3-5 seconds)
2. Connect to the remote debugging port (9232) using Chrome DevTools Protocol
3. Create a new tab or use an existing one to navigate to the target URL
4. Return control to the browser automation tools

### Step 8: Fallback
If the user chooses "No" or any step fails:
- Execute the original `browser_navigate` tool normally
- No further interception for this session

## Implementation Notes

### Detection Commands
```bash
# Check OS
uname -s  # Returns "Linux", "Darwin", etc.

# Check Chrome installation
which google-chrome
google-chrome --version
```

### Chrome Command Details
- Port: 9232 (choose an available port, avoid conflicts)
- User data directory: Isolated profile to avoid interfering with user's main Chrome
- Remote allow origins: '*' allows connections from any origin (for development safety)

### Safety Considerations
1. The remote debugging port should be bound to localhost only (default behavior)
2. Use an isolated user data directory to prevent data mixing
3. The hook should timeout if Chrome doesn't start within 30 seconds
4. Clean up: Offer to close Chrome after the session, or leave it running for future use

### Integration with AI Agents (OpenClaw, Hermes-Agent)
1. This skill should be loaded before any browser automation tasks
2. The hook should be transparent - if it fails, the agent should continue with default tools
3. Agents should know how to connect to Chrome DevTools Protocol (CDP) after Chrome is launched

## Example Usage

```python
# Pseudo-code for the hook
def browser_navigate_hook(url):
    if not is_linux_or_macos():
        return default_browser_navigate(url)
    
    if not chrome_installed():
        return default_browser_navigate(url)
    
    response = ask_user("Launch Chrome with remote debugging?")
    if response != "yes":
        return default_browser_navigate(url)
    
    ensure_directory_exists("${HOME}/.chrome-remote-debugging")
    launch_chrome_remote_debugging()
    
    # Connect via CDP and navigate
    return navigate_via_cdp(url)
```

## Troubleshooting

### Common Issues
1. **Port already in use**: Try a different port (e.g., 9233, 9234)
2. **Chrome won't start**: Check for existing Chrome processes, kill them if necessary
3. **Connection refused**: Ensure Chrome started successfully, wait longer
4. **Permission denied**: The user data directory might have wrong permissions

### Debugging Steps
1. Check if Chrome is running: `ps aux | grep chrome`
2. Test port connectivity: `curl http://localhost:9232/json`
3. Verify directory exists with correct permissions
4. Check Chrome logs for errors

## References
- Chrome DevTools Protocol: https://chromedevtools.github.io/devtools-protocol/
- Chrome command line switches: https://peter.sh/experiments/chromium-command-line-switches/
- Remote debugging documentation: https://developer.chrome.com/docs/devtools/remote-debugging/

---
**Skill Name**: browser-chrome-remote-hook  
**Category**: browser-automation  
**Tags**: chrome, remote-debugging, browser-navigation, hook  
**Version**: 1.0  
**Author**: Hermes Agent Community  
**Last Updated**: 2026-04-12