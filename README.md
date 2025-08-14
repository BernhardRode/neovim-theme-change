# nvim-theme-ipc

Dynamic theme switching for Neovim via IPC (Inter-Process Communication).

Control your Neovim theme from external applications, scripts, or system events using Unix domain sockets.

## Features

- 🎨 Change themes from outside Neovim
- 🔄 Real-time theme switching via IPC
- 📡 JSON-based command protocol
- 🛡️ Secure local socket communication
- 🔧 Easy integration with system automation
- 📋 List and validate available themes
- ⚡ Lightweight and fast

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "your-username/nvim-theme-ipc",
  config = function()
    require("theme-ipc").setup()
  end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "your-username/nvim-theme-ipc",
  config = function()
    require("theme-ipc").setup()
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'your-username/nvim-theme-ipc'
```

Then in your `init.lua`:
```lua
require("theme-ipc").setup()
```

## Configuration

```lua
require("theme-ipc").setup({
  -- Auto-start server when Neovim starts
  auto_start = true,
  
  -- Socket path (default: /tmp/nvim_theme_{pid})
  socket_path = nil,
  
  -- Enable debug logging
  debug = false,
  
  -- Allowed actions (security)
  allowed_actions = {
    "set_theme",
    "get_theme", 
    "list_themes",
    "reload_config"
  }
})
```

## Usage

### External Clients

The plugin includes command-line clients for external control:

```bash
# Using the included bash client
nvim-theme set tokyonight
nvim-theme get
nvim-theme list
nvim-theme status

# Using the Python client
python3 nvim_theme_client.py set gruvbox
python3 nvim_theme_client.py list
```

### Neovim Commands

```vim
:ThemeIPCStart    " Start the IPC server
:ThemeIPCStop     " Stop the IPC server  
:ThemeIPCStatus   " Show server status
:ThemeIPCReload   " Reload configuration
```

### Lua API

```lua
local theme_ipc = require("theme-ipc")

-- Start/stop server
theme_ipc.start_server()
theme_ipc.stop_server()

-- Get server status
local is_running = theme_ipc.is_running()
local socket_path = theme_ipc.get_socket_path()
```

## Integration Examples

### System Dark/Light Mode

```bash
#!/bin/bash
# Auto-switch based on system theme
if [ "$(gsettings get org.gnome.desktop.interface gtk-theme)" = "'Adwaita-dark'" ]; then
    nvim-theme set tokyonight
else  
    nvim-theme set github_light
fi
```

### Tmux Integration

```bash
# In your tmux config or script
bind-key C-d run-shell "nvim-theme set tokyonight"
bind-key C-l run-shell "nvim-theme set github_light"
```

### Desktop Environment

Create desktop shortcuts or bind to system hotkeys for instant theme switching.

## API Reference

### JSON Commands

All commands use JSON format over Unix domain socket:

```json
{"action": "set_theme", "theme": "tokyonight"}
{"action": "get_theme"}
{"action": "list_themes"}  
{"action": "reload_config"}
```

### Responses

```json
{"success": true, "theme": "tokyonight"}
{"current_theme": "gruvbox"}
{"themes": ["default", "blue", "darkblue", ...]}
{"error": "Theme not found: invalid_theme"}
```

## Troubleshooting

### Common Issues

**"Vimscript function must not be called in a fast event context" error:**
- This has been fixed in the latest version by using `vim.schedule()`
- Make sure you're using the updated plugin code
- If you still see this error, try restarting Neovim

**Server not starting:**
- Check if the socket path is writable
- Verify no other instance is using the same socket
- Try `:ThemeIPCStatus` to check server state

**Client connection issues:**
- Ensure Neovim is running with the plugin loaded
- Check that the socket file exists: `~/.cache/nvim/theme_socket`
- Verify socket permissions and accessibility

## Requirements

- Neovim 0.7+
- Unix-like system (Linux, macOS, WSL)
- `socat` for bash client (optional)
- `jq` for JSON parsing in bash (optional)

## License

MIT License
