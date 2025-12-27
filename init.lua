local M = {}
M.PLUGIN_NAME = "preview.vifm"

-- local path = "/Users/rio/Projects/terminal/vifm/preview.vifm/util.lua"
-- local f = io.popen('stat -f "%m" "' .. path .. '" 2>/dev/null')
-- local out = f:read("*l")
-- f:close()
-- vifm.sb.info(out)

local base = os.getenv("VIFM") .. "/plugins/preview.vifm/?.lua;"
package.path = base .. package.path

local util = require("util")
local defaults = require("defaults")

-- Load config
local config = dofile(os.getenv("VIFM") .. "/preview.lua")
config = util.deep_merge(defaults, config)

-- Global
local log_info = {} -- Keep log info (subcmd, action)

---@param category string
---@param message string
---@param info table?
function M.log(category, message, info)
  local len = {
    subcmd = 8,
    action = 10,
    category = 10,
  }
  local _info = info or log_info -- Use info if it is set
  if config.log.enabled then
    local f = assert(io.open(config.log.path, "a"))
    subcmd = string.format("%-" .. len.subcmd .. "s", _info.subcmd)
    action = string.format("%-" .. len.action .. "s", _info.action or "-")
    category = string.format("%-" .. len.category .. "s", category)
    f:write(string.format("[ %s ] %s | %s : %s\n", subcmd, action, category, message))
    f:close()
  end
end

---@param info table
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
    -- vifm.sb.info("\nset_state set to : " .. path .. " : " .. action_name .. " : " .. state) -- DEBUG:
    local hash_file = string.format("%s/%s.%s", config.cache.dir, util.get_hash(path, hash_cmd), action_name)
    local lock_file = hash_file .. ".lock"
    if state == "done" then
      cmd = string.format("rm '%s' >/dev/null 2>&1; touch '%s' >/dev/null 2>&1", lock_file, hash_file)
    elseif state == "locked" then
      cmd = string.format("touch '%s' >/dev/null 2>&1", lock_file)
    elseif state == "none" then
      cmd = string.format("rm '%s' >/dev/null 2>&1", hash_file)
    end
    util.execute(cmd)
  else
    -- Files
    local info = {
      cache_dir = config.cache.dir,
      source = path,
      hash = util.get_hash(path, hash_cmd),
    }
    -- vifm.sb.info("action_name: " .. action_name) -- DEBUG:
    -- vifm.sb.info(util.inspect(config)) -- DEBUG:
    local preview_path = config.actions[action_name].generate.preview_path(info)
    local lock_file = preview_path .. ".lock"
    if state == "done" then
      cmd = string.format("rm '%s' >/dev/null 2>&1", lock_file)
    elseif state == "locked" then
      cmd = string.format("touch '%s' >/dev/null 2>&1", lock_file)
    elseif state == "none" then
      if util.realpath(path) == util.realpath(preview_path) then
        cmd = "" -- Avoid removing the source file
      else
        cmd = string.format("rm '%s' >/dev/null 2>&1", preview_path)
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
    local hash_file = string.format("%s/%s.%s", config.cache.dir, util.get_hash(path, hash_cmd), action_name)
    local lock_file = hash_file .. ".lock"
    if vifm.exists(lock_file) then
      return "locked"
    elseif vifm.exists(hash_file) then
      return "done"
    else
      return "none"
    end
  else
    -- Files
    local info = {
      cache_dir = config.cache.dir,
      source = path,
      hash = util.get_hash(path, hash_cmd),
    }
    local preview_path = config.actions[action_name].generate.preview_path(info)
    local lock_file = preview_path .. ".lock"
    if vifm.exists(lock_file) then
      return "locked"
    elseif vifm.exists(preview_path) then
      return "done"
    else
      return "none"
    end
  end
end

---@param info table
---@param cb function?
function M.generate_preview(info, cb)
  -- Get generate command
  local hash_cmd = config.cache.hash_cmd
  local action = config.actions[info.action]
  local hash = util.get_hash(info.path, hash_cmd)
  info.dst = string.format("%s/%s.%s", config.cache.dir, hash, action.generate.ext)

  -- Check if generation is necessary
  if action.generate.cmd == "" then return end
  local preview_exists = vifm.exists(info.dst)
  if preview_exists and not info.force then -- TODO: Add state check ?
    M.log("info", "Skipped preview generation for '" .. info.path .. "'")
    if type(cb) == "function" then cb(info) end
    return
  end
  local preview_mtime = util.get_mtime(info.dst)
  local source_mtime = util.get_mtime(info.path)
  preview_mtime = preview_mtime or 0
  local preview_older = preview_mtime < source_mtime
  if not preview_older and not info.force then return end

  -- Get cmd
  local args = {
    src = info.path,
    dst = info.dst,
  }
  local cmd = util.get_cmd(action.generate.cmd, args)
  if cmd == "" then return end

  -- Generate
  if type(cb) == "function" then
    util.execute(cmd .. " >/dev/null 2>&1") -- Sync and callback
    if cb then cb(info) end
  else
    util.execute(cmd .. " >/dev/null 2>&1 &") -- Async
  end
end

---Generate previews for all files in dir
---@param info table
function M.generate_preview_all(info)
  M.log("function", "(in ) generate_preview_all()")
  -- local saved_log_info = util.deep_copy(log_info)
  -- local saved_info = util.deep_copy(info)
  local cwd = info.path

  local _info = util.deep_copy(info) -- Temporary info
  for action_name, action in pairs(config.actions) do
    _info.action = action_name -- Set current `action`
    M.log("loop", action_name .. " action", _info)
    if info.force then M.set_state(cwd, action_name, "none") end
    local state = M.get_state(cwd, action_name)
    if state == "locked" or state == "done" then return end -- Exit if locked or done
    M.set_state(cwd, action_name, "locked")
    local files = util.glob(cwd, action.patterns)
    M.log("files", util.inspect(files, 0, false):gsub("%[%d*%] = ", ""))
    -- Loop for the all pattern matched files
    M.log("loop", util.inspect(action.patterns, 0, false):gsub("%[%d*%] = ", ""))
    for _, file in ipairs(files) do
      if util.realpath(file) ~= util.realpath(info.path) then -- Skip if current file
        _info.path = file -- Set current `path`
        _info.force = true
        M.generate_preview(_info, nil)
      end
    end
    M.set_state(cwd, action_name, "done")
  end
  -- info = util.deep_copy(saved_info) -- Restore info
  -- log_info = util.deep_copy(saved_log_info) -- Restore log_info (NOTE: `log_info.action` will be contaminated with async generate_preview() function)
  M.log("function", "(out) generate_preview_all()")
end

-- clear command
local function clear(info)
  log_info = get_info_command_parts(info)
  M.log("function", "(in ) clear()")
  info.tty = os.getenv("VIFM_PREVIEW_TTY")
  local cmd = config.command.clear
  cmd = util.get_cmd(cmd, info)
  M.log("command", cmd)
  util.execute(cmd)
  M.log("function", "(out) clear()")
end

local function show(info)
  M.log("function", "(in ) show()")

  local view = vifm.currview()
  local entry = view:entry(view.cursor.pos)
  local curr_path = entry.location .. "/" .. entry.name
  -- vifm.sb.info(util.inspect(entry))
  if util.realpath(info.path) ~= curr_path then -- Skip if the cursor is already moved out
    vifm.sb.info("skip show for " .. entry.name)
    return
  end

  local cmd = config.command.show
  local env = util.get_environment()
  if env.nvim then
    info.x = info.x + os.getenv("VIFM_PREVIEW_WIN_X") + os.getenv("VIFM_PREVIEW_WIN_BORDER_WIDTH")
    info.y = info.y + os.getenv("VIFM_PREVIEW_WIN_Y") + os.getenv("VIFM_PREVIEW_WIN_BORDER_WIDTH")
  end
  M.log("info", "info = " .. util.inspect(info, 0, false))
  cmd = util.get_cmd(cmd, info)
  M.log("command", cmd)
  util.execute(cmd)

  M.log("function", "(out) show()")
end

---Refresh all cache files for cwd
local function refresh()
  log_info = { subcmd = "refresh", action = "-", rest = nil }
  M.log("function", "(in ) refresh()")
  vifm.sb.info("Refreshing preview caches...")

  local cwd = vifm.currview().cwd
  local info = {
    path = cwd,
    tty = os.getenv("VIFM_PREVIEW_TTY"),
    force = true,
  }

  M.generate_preview_all(info) -- force generation
  vifm.sb.info("Refreshed preview caches for '" .. cwd .. "'")
  M.log("function", "(out) refresh()")
end

---Delete all cache files
---@param info table vifm.info
local function delete(info)
  log_info = { subcmd = "delete", action = "-", rest = nil }
  -- TODO: Add delete code
  util.execute('touch "/Users/rio/.cache/vifm/preview/test.txt"')
end

-- NOTE: 結論: 現状では coroutine は expose されてないので使えない。
-- local coroutine = require("coroutine") -- NG
-- print(util.inspect(_G)) -- NG
-- print(_G.coroutine) -- nil
--
-- -- DEBUG: A test for coroutine
-- local co = coroutine.create(function()
--   for i = 1, 10 do
--     vifm.sb.info("co: ", i)
--   end
-- end)
--
-- coroutine.resume(co)

-- NOTE: This is the solution
-- Set below code to vifmrc
-- `let $VIFM_SERVER_NAME = v:servername`
-- Then
vifm.sb.info("$VIFM_SERVER_NAME: " .. os.getenv("VIFM_SERVER_NAME"))

local function preview(info)
  log_info = get_info_command_parts(info)
  M.log("function", "(in ) preview()")
  info.tty = os.getenv("VIFM_PREVIEW_TTY")

  -- vifm.sb.info(action .. ":\n" .. util.inspect(info))
  local action = config.actions[info.action]
  if not action then
    local mes = string.format("%s action is not defined.", info.action)
    vifm.sb.error(mes)
    return
  end
  -- vifm.sb.info(table.concat(action.patterns, ","))

  -- sleep(config.preview_delay / 1000) -- DEBUG: REMOVE
  -- vifm.sb.info(os.time())

  -- Generate for current file
  M.generate_preview(info, function(_info) show(_info) end) -- DEBUG: ⭐️ ここを `vifm -remote -c ""` にするのでは？

  -- Generate for all files in current dir
  local cwd = vifm.currview().cwd
  M.log("info", "cwd = '" .. cwd .. "'")
  info.path = cwd
  M.generate_preview_all(info) -- DEBUG: ここは async にしなくていいのか？ 諸々のチェックで、多少の UI ブロッキングはしているぞ？
  M.log("function", "(out) preview()")
end

-- Handlers are called by `fileviewer` command in vifmrc
vifm.addhandler({
  name = "preview",
  handler = function(info)
    -- vifm.sb.info("info: " .. util.inspect(info)) -- TEST:
    -- Re-format info table
    info.action = info.command:match("^#" .. M.PLUGIN_NAME .. "#preview (%S+)")
    info.force = false
    preview(info)
  end,
})

vifm.addhandler({
  name = "clear",
  handler = function(info) clear(info) end,
})

vifm.addhandler({
  name = "refresh",
  handler = function(info) refresh(info) end,
})

vifm.addhandler({
  name = "delete",
  handler = function(info) delete(info) end,
})

vifm.cmds.add({
  name = "preview",
  handler = function(info)
    -- vifm.sb.info(util.inspect(info.argv, 0, false))
    if #info.argv == 0 then
      vifm.sb.error("Specify subcmd ':preview {preview|refresh|delete}'")
      return
    end
    -- vifm.sb.info("info: " .. util.inspect(info)) -- TEST:
    local subcmd = info.argv[1]
    if subcmd == "preview" then
      -- preview {action} {x} {y} {width} {height} {path} {force}
      -- #1      #2       #3  #4  #5      #6       #7     #8
      info.subcmd = info.argv[1]
      info.action = info.argv[2]
      info.x = info.argv[3]
      info.y = info.argv[4]
      info.width = info.argv[5]
      info.height = info.argv[6]
      info.path = info.argv[7]
      info.force = info.argv[8]
      preview(info)
    elseif subcmd == "refresh" then
      refresh(info)
    elseif subcmd == "delete" then
      delete(info)
    end
  end,
  minargs = 0,
  maxargs = -1,
})

vifm.sb.info("init.lua is loaded.")

return M
