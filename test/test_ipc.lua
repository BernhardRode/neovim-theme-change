-- test_ipc.lua - Test script for the IPC functionality
-- Run this in Neovim to test the plugin

local function test_theme_ipc()
  print("Testing nvim-theme-ipc plugin...")
  
  -- Load the plugin
  local theme_ipc = require("theme-ipc")
  
  -- Setup with debug enabled
  theme_ipc.setup({
    debug = true,
    auto_start = false  -- We'll start manually for testing
  })
  
  -- Start the server
  print("Starting IPC server...")
  local success = theme_ipc.start_server()
  if success then
    print("✓ Server started successfully")
  else
    print("✗ Failed to start server")
    return
  end
  
  -- Check status
  local status = theme_ipc.get_status()
  print("Server status:")
  print("  Running: " .. tostring(status.running))
  print("  Socket: " .. (status.socket_path or "unknown"))
  print("  Clients: " .. status.client_count)
  
  -- Wait a moment for the server to be ready
  vim.defer_fn(function()
    print("\nServer is ready for external connections!")
    print("Try running from another terminal:")
    print("  " .. vim.fn.stdpath('cache') .. "/theme_socket")
    print("  ./bin/nvim-theme status")
    print("  ./bin/nvim-theme list")
    print("  ./bin/nvim-theme get")
    
    -- Test internal functionality
    print("\nTesting internal functions...")
    
    -- Test getting current theme
    local current = vim.g.colors_name or "default"
    print("Current theme: " .. current)
    
    -- Test listing themes (this should work now with vim.schedule)
    local themes = vim.fn.getcompletion('', 'color')
    print("Available themes: " .. #themes .. " found")
    if #themes > 0 then
      print("  First few: " .. table.concat(vim.list_slice(themes, 1, math.min(5, #themes)), ", "))
    end
    
    print("\n✓ Internal tests completed")
    print("Now test external clients!")
  end, 1000)
end

-- Run the test
test_theme_ipc()
