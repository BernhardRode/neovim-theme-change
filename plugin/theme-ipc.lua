-- plugin/theme-ipc.lua
-- Plugin entry point for traditional Vim plugin loading

if vim.g.loaded_theme_ipc then
  return
end
vim.g.loaded_theme_ipc = 1

-- Only load if Neovim version is supported
if vim.fn.has('nvim-0.7') == 0 then
  vim.api.nvim_err_writeln('theme-ipc requires Neovim 0.7+')
  return
end

-- The actual plugin logic is in lua/theme-ipc/init.lua
-- This file just ensures compatibility with traditional plugin managers
