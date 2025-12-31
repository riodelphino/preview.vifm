local M = {}

---@class vifm.preview.Info
---@field command string?
---@field args table?
---@field argv table?
---@field subcmd string?
---@field action string?
---@field path string?
---@field x number?
---@field y number?
---@field width number?
---@field height number?
---@field force boolean?
---@field src string? -- = path
---@field dst string?
---@field tty string?

-- Get/Set statics
M.PLUGIN_NAME = "preview.vifm"
M.TTY = os.getenv("VIFM_PREVIEW_TTY")
M.SERVER_NAME = os.getenv("VIFM_SERVER_NAME") -- Get v:servername (Need $VIFM_SERVER_NAME is set in vifmrc)

local base = os.getenv("VIFM") .. "/plugins/preview.vifm/?.lua;"
package.path = base .. package.path

local util = require("util")
local defaults = require("defaults")

-- Load config
local config = dofile(os.getenv("VIFM") .. "/preview.lua")
config = util.deep_merge(defaults, config)

-- Create log dir
if config.log.enabled then
  local parent = vifm.fnamemodify(config.log.path, ":h")
  util.execute(string.format("mkdir -p %s", parent))
end

-- Create cache dir
if config.cache.enabled then
  local cache_dir = config.cache.dir
  util.execute(string.format("mkdir -p %s", cache_dir))
end

---@param category string
---@param message string
---@param info vifm.preview.Info
function M.log(category, message, info)
  local len = {
    subcmd = 8,
    action = 10,
    category = 10,
  }
  if config.log.enabled then
    local f = assert(io.open(config.log.path, "a"))
    subcmd = string.format("%-" .. len.subcmd .. "s", info.subcmd)
    action = string.format("%-" .. len.action .. "s", info.action or "-")
    category = string.format("%-" .. len.category .. "s", category)
    f:write(string.format("[ %s ] %s | %s : %s\n", subcmd, action, category, message))
    f:close()
  end
end

---@param info vifm.preview.Info
---@return table command_parts
local function get_info_command_parts(info)
  local subcmd, action, rest
  subcmd, rest = info.command:match("^#" .. M.PLUGIN_NAME .. "#(%S+)%s*(.*)$")
  if rest and rest ~= "" then
    action, rest = rest:match("^(%S+)%s*(.*)$")
  end
  return { subcmd = subcmd, action = action, rest = rest }
end

---@param path string
---@param action_name string
---@param state "done"|"locked"|"none"
function M.set_state(path, action_name, state)
  local hash_cmd = config.cache.hash_cmd
  local cmd
  if util.is_dir(path) then
    -- Directories
    local cache_file = string.format("%s/%s.%s", config.cache.dir, util.get_hash(path, hash_cmd), action_name)
    local lock_file = cache_file .. ".lock"
    if state == "done" then
      cmd = string.format("rm '%s' >/dev/null 2>&1; touch '%s' >/dev/null 2>&1", lock_file, cache_file)
    elseif state == "locked" then
      cmd = string.format("touch '%s' >/dev/null 2>&1", lock_file)
    elseif state == "none" then
      cmd = string.format("rm '%s' >/dev/null 2>&1", cache_file)
    end
    util.execute(cmd)
  else
    -- Files
    local action = config.actions[action_name]
    local cache_file = util.get_cache_filepath(path, config.cache.dir, action.cache.ext, hash_cmd)
    local lock_file = cache_file .. ".lock"
    if state == "done" then
      cmd = string.format("rm '%s' >/dev/null 2>&1", lock_file)
    elseif state == "locked" then
      cmd = string.format("touch '%s' >/dev/null 2>&1", lock_file)
    elseif state == "none" then
      if util.realpath(path) == util.realpath(cache_file) then
        cmd = "" -- Avoid removing the source file
      else
        cmd = string.format("rm '%s' >/dev/null 2>&1", cache_file)
      end
    end
    util.execute(cmd)
  end
end

---@param path string
---@param action_name string
---@return "done"|"locked"|"none"
function M.get_state(path, action_name)
  local hash_cmd = config.cache.hash_cmd
  if util.is_dir(path) then
    -- Directories
    local cache_file = string.format("%s/%s.%s", config.cache.dir, util.get_hash(path, hash_cmd), action_name)
    local lock_file = cache_file .. ".lock"
    if vifm.exists(lock_file) then
      return "locked"
    elseif vifm.exists(cache_file) then
      return "done"
    else
      return "none"
    end
  else
    -- Files
    local action = config.actions[action_name]
    local cache_file = util.get_cache_filepath(path, config.cache.dir, action.cache.ext, hash_cmd)
    local lock_file = cache_file .. ".lock"
    if vifm.exists(lock_file) then
      return "locked"
    elseif vifm.exists(cache_file) then
      return "done"
    else
      return "none"
    end
  end
end

---@param info vifm.preview.Info
---@param cb function?
function M.generate(info, cb)
  -- Get generate command
  local hash_cmd = config.cache.hash_cmd
  local action = config.actions[info.action]
  info.dst = util.get_cache_filepath(info.path, config.cache.dir, action.cache.ext, hash_cmd)

  -- Check cmd
  if action.cmd.generate == "" then
    M.log("error", string.format("Set '%s.cmd.generate'. (It's nil or ''.)", info.action), info)
    return
  end
  -- Check if cache is enabled
  if not config.cache.enabled then
    M.log("error", string.format("Caching is disabled by 'config.cache.enabled'", info.action), info)
    if type(cb) == "function" then cb(info) end
    return
  end
  local state = M.get_state(info.path, info.action)
  -- Check state
  if state == "done" and not info.force then
    M.log("info", "Skipped generation for '" .. info.path .. "' (done)", info)
    if type(cb) == "function" then cb(info) end
    return
  elseif state == "locked" then
    M.log("info", "Skipped generation for '" .. info.path .. "' (locked)", info)
    return
  end
  -- Check mtime
  local preview_mtime = util.get_mtime(info.dst)
  local source_mtime = util.get_mtime(info.path)
  preview_mtime = preview_mtime or 0
  local preview_older = preview_mtime < source_mtime
  if not preview_older and not info.force then
    return
  else
    M.log("info", "Update preview for '" .. info.path .. "' (preview older)", info)
  end

  -- Set state
  M.set_state(info.path, info.action, "locked")

  -- Get cmd
  local args = {
    src = info.path,
    dst = info.dst,
  }
  local cmd = util.get_cmd(action.cmd.generate, args)
  if cmd == "" then return end

  -- Generate
  if type(cb) == "function" then
    util.execute(cmd .. " >/dev/null 2>&1") -- Sync and callback
    cb(info)
  else
    util.execute(cmd .. " >/dev/null 2>&1 &") -- Async
  end

  -- Set state
  M.set_state(info.path, info.action, "done")
end

---Generate previews for all files in dir
---@param info vifm.preview.Info
function M.generate_all(info)
  M.log("function", "(in ) generate_all()", info)
  -- Check if cache is enabled
  if not config.cache.enabled then
    M.log("error", string.format("Caching is disabled by 'config.cache.enabled'", info.action), info)
    M.log("function", "(out) generate_all()", info)
    return
  end
  local cwd = info.path ---@type string

  local _info = util.deep_copy(info) -- Temporary info
  for action_name, action in pairs(config.actions) do
    _info.action = action_name -- Set current `action`
    M.log("loop", action_name .. " action", _info)

    if info.force then M.set_state(cwd, action_name, "none") end
    local state = M.get_state(cwd, action_name)
    if state == "locked" or state == "done" then return end -- Exit if locked or done
    M.set_state(cwd, action_name, "locked")

    local files = util.glob(cwd, action.patterns)
    M.log("files", util.inspect(files, 0, false), _info)
    M.log("loop", action.patterns, _info)

    for _, file in ipairs(files) do
      if util.realpath(file) ~= util.realpath(info.path) then
        _info.path = file
        M.generate(_info, nil)
      end
    end
    M.set_state(cwd, action_name, "done")
  end
  M.log("function", "(out) generate_all()", info)
end

-- clear command
local function clear(info)
  M.log("function", "(in ) clear()", info)
  local state = M.get_state(info.path, info.action)
  if state == "locked" then
    M.log("info", "Skipped clear for '" .. info.path .. "' (locked)", info)
    M.log("function", "(out) clear()", info)
    return
  end
  info.tty = M.TTY

  local action = config.actions[info.action]
  local cmd = action.cmd.clear or config.common.cmd.clear -- Prefer action-specific clear ommand. Fallback to common one

  cmd = util.get_cmd(cmd, info)
  M.log("command", cmd, info)
  util.execute(cmd)
  M.log("function", "(out) clear()", info)
end

local function show(info)
  M.log("function", "(in ) show()", info)
  local curr_path = util.get_current_filepath()
  if util.realpath(info.path) ~= util.realpath(curr_path) then -- Skip if the cursor is already moved out
    M.log("info", "skipped show() (the cursor is already moved out): " .. vifm.fnamemodify(curr_path, ":t"), info)
    return
  end

  local action = config.actions[info.action]
  local cmd = action.cmd.show or config.common.cmd.show -- Prefer action-specific show command. Fallback to common one

  local env = util.get_environment()
  if env.nvim then
    info.x = info.x + os.getenv("VIFM_PREVIEW_WIN_X") + os.getenv("VIFM_PREVIEW_WIN_BORDER_WIDTH")
    info.y = info.y + os.getenv("VIFM_PREVIEW_WIN_Y") + os.getenv("VIFM_PREVIEW_WIN_BORDER_WIDTH")
  end

  M.log("info", "info = " .. util.inspect(info, 0, false), info)
  if not config.cache.enabled then
    info.dst = info.path -- Use source file to preview
  end
  cmd = util.get_cmd(cmd, info)
  M.log("command", cmd, info)
  util.execute(cmd)

  M.log("function", "(out) show()", info)
end

---Refresh all cache files for cwd
local function refresh(info)
  -- log_info = { subcmd = "refresh", action = "-", rest = nil }
  M.log("function", "(in ) refresh()", info)
  vifm.sb.info("Refreshing preview caches...")

  local cwd = vifm.currview().cwd
  info.path = cwd
  info.tty = M.TTY
  info.force = true

  M.generate_all(info) -- force generation
  vifm.sb.info("Refreshed preview caches for '" .. cwd .. "'")
  M.log("function", "(out) refresh()", info)
end

---Delete all cache files
---@param info vifm.preview.Info
local function delete(info)
  M.log("function", "(in ) delete()", info)
  local cmd = string.format("rm -rf %s/*", config.cache.dir)
  util.execute(cmd)
  local msg = string.format("Deleted all caches in '%s'", config.cache.dir)
  vifm.sb.info(msg)
  M.log("info", msg, info)
  M.log("function", "(out) delete()", info)
end

---generate() -> show(), additionally run generate_all()
---@param info vifm.preview.Info
local function preview(info)
  log_info = get_info_command_parts(info)
  M.log("function", "(in ) preview()", info)
  info.tty = M.TTY

  local action = config.actions[info.action]
  if not action then
    local mes = string.format("%s action is not defined.", info.action)
    vifm.sb.error(mes)
    return
  end

  -- Generate for current file
  M.generate(info, function(_info) show(_info) end)

  -- Generate for all files in current dir in background
  local cwd = vifm.currview().cwd

  M.log("info", "cwd = '" .. cwd .. "'", info)
  info.path = cwd
  M.generate_all(info)

  M.log("function", "(out) preview()", info)
end

-- ╭───────────────────────────────────────────────────────────────╮
-- │                Setup handlers for `fileviewer`                │
-- ╰───────────────────────────────────────────────────────────────╯
-- Setup:
--   1. preview
--   2. clear
-- That's all and enough.

-- Handlers are called by `fileviewer` command in vifmrc
vifm.addhandler({
  name = "preview",
  handler = function(info)
    -- Re-format info table
    info.subcmd = "preview"
    info.action = info.command:match("^#" .. M.PLUGIN_NAME .. "#" .. info.subcmd .. " (%S+)")
    info.force = false
    preview(info)
  end,
})

vifm.addhandler({
  name = "clear",
  handler = function(info)
    info.subcmd = "clear"
    info.action = info.command:match("^#" .. M.PLUGIN_NAME .. "#" .. info.subcmd .. " (%S+)")
    clear(info)
  end,
})

-- ╭───────────────────────────────────────────────────────────────╮
-- │                      Setup vifm command                       │
-- ╰───────────────────────────────────────────────────────────────╯
-- Purpose:
--   1. To call from keymaps
--   2. To call asynchronously by 'init.lua'-self (Deprecated)

---Setup `:preview` command
vifm.cmds.add({
  name = "preview",
  handler = function(info)
    -- vifm.sb.info(util.inspect(info.argv, 0, false))
    if #info.argv == 0 then
      vifm.sb.error("Specify subcmd ':preview {generate|refresh|delete}'")
      return
    end
    info.subcmd = info.argv[1]
    M.log("command", "(in ) preview", info)
    if info.subcmd == "refresh" then
      info.action = "-"
      refresh(info)
    elseif info.subcmd == "delete" then
      info.action = "-"
      delete(info)
    elseif info.subcmd == "generate" then -- (Deprecated)
      -- Asynchronously called by `fileviewer` in vifmrc
      -- -- :preview generate {action} {x} {y} {width} {height} {path} {force}
      -- --          #1       #2       #3  #4  #5      #6       #7     #8
      -- info.subcmd = info.argv[1]
      -- info.action = info.argv[2]
      -- info.x = info.argv[3]
      -- info.y = info.argv[4]
      -- info.width = info.argv[5]
      -- info.height = info.argv[6]
      -- info.path = util.unquote(info.argv[7])
      -- info.force = info.argv[8]
      -- info.tty = M.TTY
      -- M.generate(info, function() show(info) end)
    end
    M.log("command", "(out) preview", info)
  end,
  minargs = 0,
  maxargs = -1,
})

return M
