-- theme-ipc/init.lua
local M = {}

local uv = vim.loop
local api = vim.api

-- Default configuration
local default_config = {
  auto_start = true,
  socket_path = nil,
  debug = false,
  allowed_actions = {
    "set_theme",
    "get_theme",
    "list_themes",
    "reload_config"
  }
}

-- Plugin state
local state = {
  server = nil,
  socket_path = nil,
  config = {},
  clients = {}
}

-- Utility functions
local function log(msg, level)
  if state.config.debug then
    vim.notify("[theme-ipc] " .. msg, level or vim.log.levels.INFO)
  end
end

local function get_cache_dir()
  return vim.fn.stdpath('cache')
end

local function get_socket_path()
  if state.config.socket_path then
    return state.config.socket_path
  end
  return "/tmp/nvim_theme_" .. vim.fn.getpid()
end

local function save_socket_path(path)
  local cache_dir = get_cache_dir()
  vim.fn.mkdir(cache_dir, 'p')
  vim.fn.writefile({path}, cache_dir .. '/theme_socket')
end

local function is_action_allowed(action)
  return vim.tbl_contains(state.config.allowed_actions, action)
end

-- Command handlers
local function handle_set_theme(params)
  if not params.theme then
    return {error = "Theme name required"}
  end
  
  local success, err = pcall(vim.cmd, 'colorscheme ' .. params.theme)
  if success then
    log("Theme changed to: " .. params.theme)
    return {success = true, theme = params.theme}
  else
    log("Failed to set theme: " .. params.theme .. " - " .. tostring(err), vim.log.levels.ERROR)
    return {error = "Theme not found: " .. params.theme}
  end
end

local function handle_get_theme()
  local current = vim.g.colors_name or "default"
  return {current_theme = current}
end

local function handle_list_themes()
  local themes = vim.fn.getcompletion('', 'color')
  return {themes = themes}
end

local function handle_reload_config()
  local success, err = pcall(vim.cmd, 'source $MYVIMRC')
  if success then
    log("Configuration reloaded")
    return {success = true, message = "Config reloaded"}
  else
    log("Failed to reload config: " .. tostring(err), vim.log.levels.ERROR)
    return {error = "Failed to reload config"}
  end
end

-- Main command handler
local function handle_command(data)
  local ok, command = pcall(vim.json.decode, data)
  if not ok then
    return {error = "Invalid JSON"}
  end
  
  if not command.action then
    return {error = "Action required"}
  end
  
  if not is_action_allowed(command.action) then
    return {error = "Action not allowed: " .. command.action}
  end
  
  log("Handling command: " .. command.action)
  
  if command.action == "set_theme" then
    return handle_set_theme(command)
  elseif command.action == "get_theme" then
    return handle_get_theme()
  elseif command.action == "list_themes" then
    return handle_list_themes()
  elseif command.action == "reload_config" then
    return handle_reload_config()
  else
    return {error = "Unknown action: " .. command.action}
  end
end

-- Client connection handler
local function handle_client(client)
  table.insert(state.clients, client)
  
  client:read_start(function(err, data)
    if err then
      log("Client read error: " .. tostring(err), vim.log.levels.ERROR)
      return
    end
    
    if data then
      local response = handle_command(data:gsub("%s+$", ""))
      local json_response = vim.json.encode(response)
      client:write(json_response .. "\n")
    else
      -- Client disconnected
      client:close()
      for i, c in ipairs(state.clients) do
        if c == client then
          table.remove(state.clients, i)
          break
        end
      end
      log("Client disconnected")
    end
  end)
end

-- Server functions
function M.start_server()
  if state.server then
    log("Server already running")
    return true
  end
  
  state.server = uv.new_pipe(false)
  state.socket_path = get_socket_path()
  
  -- Clean up any existing socket
  uv.fs_unlink(state.socket_path)
  
  local success, err = pcall(function()
    state.server:bind(state.socket_path)
    state.server:listen(128, function(listen_err)
      if listen_err then
        log("Server listen error: " .. tostring(listen_err), vim.log.levels.ERROR)
        return
      end
      
      local client = uv.new_pipe(false)
      state.server:accept(client)
      handle_client(client)
    end)
  end)
  
  if not success then
    log("Failed to start server: " .. tostring(err), vim.log.levels.ERROR)
    state.server = nil
    return false
  end
  
  save_socket_path(state.socket_path)
  log("Server started on: " .. state.socket_path)
  return true
end

function M.stop_server()
  if not state.server then
    log("Server not running")
    return
  end
  
  -- Close all clients
  for _, client in ipairs(state.clients) do
    client:close()
  end
  state.clients = {}
  
  -- Close server
  state.server:close()
  state.server = nil
  
  -- Clean up socket file
  if state.socket_path then
    uv.fs_unlink(state.socket_path)
    state.socket_path = nil
  end
  
  log("Server stopped")
end

function M.is_running()
  return state.server ~= nil
end

function M.get_socket_path()
  return state.socket_path
end

function M.get_status()
  return {
    running = M.is_running(),
    socket_path = state.socket_path,
    client_count = #state.clients,
    config = state.config
  }
end

-- Setup function
function M.setup(opts)
  opts = opts or {}
  state.config = vim.tbl_deep_extend("force", default_config, opts)
  
  -- Create user commands
  api.nvim_create_user_command('ThemeIPCStart', function()
    if M.start_server() then
      print("Theme IPC server started")
    else
      print("Failed to start Theme IPC server")
    end
  end, {desc = "Start Theme IPC server"})
  
  api.nvim_create_user_command('ThemeIPCStop', function()
    M.stop_server()
    print("Theme IPC server stopped")
  end, {desc = "Stop Theme IPC server"})
  
  api.nvim_create_user_command('ThemeIPCStatus', function()
    local status = M.get_status()
    if status.running then
      print("Theme IPC server is running")
      print("Socket: " .. (status.socket_path or "unknown"))
      print("Clients: " .. status.client_count)
    else
      print("Theme IPC server is not running")
    end
  end, {desc = "Show Theme IPC server status"})
  
  api.nvim_create_user_command('ThemeIPCReload', function()
    M.stop_server()
    vim.defer_fn(function()
      M.start_server()
      print("Theme IPC server reloaded")
    end, 100)
  end, {desc = "Reload Theme IPC server"})
  
  -- Auto-start if configured
  if state.config.auto_start then
    api.nvim_create_autocmd("VimEnter", {
      callback = function()
        M.start_server()
      end,
      desc = "Auto-start Theme IPC server"
    })
  end
  
  -- Cleanup on exit
  api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      M.stop_server()
    end,
    desc = "Stop Theme IPC server on exit"
  })
  
  log("Theme IPC plugin initialized")
end

return M
