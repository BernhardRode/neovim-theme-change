-- Example Neovim configuration with nvim-theme-ipc

-- Basic plugin setup with lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin configuration
require("lazy").setup({
  -- Theme IPC plugin
  {
    "your-username/nvim-theme-ipc",
    config = function()
      require("theme-ipc").setup({
        auto_start = true,
        debug = false,
        -- Custom socket path (optional)
        -- socket_path = "/tmp/my_nvim_theme_socket",
        
        -- Security: limit allowed actions
        allowed_actions = {
          "set_theme",
          "get_theme",
          "list_themes",
          "reload_config"
        }
      })
    end
  },
  
  -- Some popular themes to test with
  { "folke/tokyonight.nvim" },
  { "catppuccin/nvim", name = "catppuccin" },
  { "ellisonleao/gruvbox.nvim" },
  { "projekt0n/github-nvim-theme" },
})

-- Set a default theme
vim.cmd.colorscheme("tokyonight")

-- Optional: Create some keybindings for manual control
vim.keymap.set('n', '<leader>ts', ':ThemeIPCStatus<CR>', { desc = 'Theme IPC Status' })
vim.keymap.set('n', '<leader>tr', ':ThemeIPCReload<CR>', { desc = 'Theme IPC Reload' })

-- Optional: Auto-commands for theme events
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    print("Theme changed to: " .. (vim.g.colors_name or "unknown"))
  end
})
