-- Functions that are called in response to autocommands
local backends = require("aerial.backends")
local config = require("aerial.config")
local data = require("aerial.data")
local fold = require("aerial.fold")
local util = require("aerial.util")
local render = require("aerial.render")
local window = require("aerial.window")

local M = {}

local function is_sticky(behavior)
  return behavior == "persist" or behavior == "global"
end

local function close_orphans()
  local orphans = util.get_aerial_orphans()
  for _, winid in ipairs(orphans) do
    if is_sticky(config.close_behavior) then
      render.clear_buffer(vim.api.nvim_win_get_buf(winid))
    else
      vim.api.nvim_win_close(winid, true)
    end
  end
end

M.on_enter_buffer = function()
  backends.attach()
  if util.is_floating_win() then
    return
  end

  local mybuf = vim.api.nvim_get_current_buf()
  if not util.is_aerial_buffer(mybuf) then
    if config.close_behavior == "close" then
      close_orphans()
    end

    -- If we're not in supported buffer
    local backend = backends.get()
    if not backend then
      fold.restore_foldmethod()
      close_orphans()
      return
    end

    fold.maybe_set_foldmethod()
  end

  if util.is_aerial_buffer(mybuf) then
    if
      (not is_sticky(config.close_behavior) and util.is_aerial_buffer_orphaned(mybuf))
      or vim.tbl_count(vim.api.nvim_list_wins()) == 1
    then
      vim.cmd("quit")
    else
      -- Hack to ignore winwidth
      vim.api.nvim_win_set_width(0, util.get_width())
    end
  elseif window.is_open() then
    close_orphans()
    render.update_aerial_buffer()
  else
    local orphans = util.get_aerial_orphans()
    if not vim.tbl_isempty(orphans) then
      -- open our symbols in that window
      vim.defer_fn(function()
        window.open(false, nil, { winid = orphans[1] })
      end, 5)
    else
      vim.defer_fn(function()
        window.maybe_open_automatic()
      end, 5)
    end
  end
end

M.on_buf_delete = function(bufnr)
  data[bufnr] = nil
end

M.on_cursor_move = function()
  window.update_position(0, true)
end

M.attach_autocommands = function(bufnr)
  if not bufnr or bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  vim.cmd(
    string.format(
      "autocmd CursorMoved <buffer=%d> lua require'aerial.autocommands'.on_cursor_move()",
      bufnr
    )
  )
  vim.cmd(
    string.format(
      [[autocmd BufDelete <buffer=%d> call luaeval("require'aerial.autocommands'.on_buf_delete(_A)", expand('<abuf>'))]],
      bufnr
    )
  )
end

return M
