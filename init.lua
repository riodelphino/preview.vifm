local M = {}

local cnt = 0 -- DEBUG:
M.PREV_PATH = ""
M.REMOTE = false

-- Get/Set statics
M.PLUGIN_NAME = "preview.vifm"
M.TTY = os.getenv("VIFM_PREVIEW_TTY")
M.SERVER_NAME = os.getenv("VIFM_SERVER_NAME")

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
---@param info table?
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
function M.generate(info, cb)
  -- Get generate command
  local hash_cmd = config.cache.hash_cmd
  local action = config.actions[info.action]
  local hash = util.get_hash(info.path, hash_cmd)
  info.dst = string.format("%s/%s.%s", config.cache.dir, hash, action.generate.ext)

  -- Check if generation is necessary
  if action.generate.cmd == "" then return end
  local preview_exists = vifm.exists(info.dst)
  if preview_exists and not info.force then -- TODO: Add state check ?
    M.log("info", "Skipped preview generation for '" .. info.path .. "'", info)
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
    cb(info)
  else
    util.execute(cmd .. " >/dev/null 2>&1 &") -- Async
  end

  -- -- DEBUG: async どーだい？
  -- if info.remote then M.REMOTE = false end
end

---Generate previews for all files in dir
---@param info table
function M.generate_all(info)
  M.log("function", "(in ) generate_all()", info)
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
    M.log("files", util.inspect(files, 0, false):gsub("%[%d*%] = ", ""), _info)
    -- Loop for the all pattern matched files
    M.log("loop", util.inspect(action.patterns, 0, false):gsub("%[%d*%] = ", ""), _info)
    for _, file in ipairs(files) do
      if util.realpath(file) ~= util.realpath(info.path) then -- Skip if current file
        _info.path = file -- Set current `path`
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
  info.tty = M.TTY
  local cmd = config.command.clear
  cmd = util.get_cmd(cmd, info)
  M.log("command", cmd, info)
  util.execute(cmd)
  M.log("function", "(out) clear()", info)
end

local function show(info)
  M.log("function", "(in ) show()", info)
  local curr_path = util.get_current_filepath()
  if util.realpath(info.path) ~= util.realpath(curr_path) then -- Skip if the cursor is already moved out
    M.log("info", "skip show for " .. vifm.fnamemodify(curr_path, ":t"), info)
    M.log("info", "info.path: " .. info.path, info) -- DEBUG:
    M.log("info", "cur_path : " .. curr_path, info) -- DEBUG:

    return
  end

  local cmd = config.command.show
  local env = util.get_environment()
  if env.nvim then
    info.x = info.x + os.getenv("VIFM_PREVIEW_WIN_X") + os.getenv("VIFM_PREVIEW_WIN_BORDER_WIDTH")
    info.y = info.y + os.getenv("VIFM_PREVIEW_WIN_Y") + os.getenv("VIFM_PREVIEW_WIN_BORDER_WIDTH")
  end
  M.log("info", "info = " .. util.inspect(info, 0, false), info)
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
---@param info table
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
---@param info table
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

  -- if M.PREV_PATH == info.path then
  --   M.log("info", "same path. abort.", info)
  --   M.log("function", "(out ) preview()", info)
  --   return
  -- end
  -- if M.REMOTE then
  --   M.log("info", "remote is running. abort.", info)
  --   M.log("function", "(out ) preview()", info)
  --   return
  -- end

  -- sleep(config.preview.delay / 1000) -- DEBUG: REMOVE
  -- vifm.sb.info(os.time())

  -- Generate for current file
  M.generate(info, function(_info) show(_info) end) -- DEBUG: ⭐️ ここを `vifm -remote -c ""` にするのでは？

  -- -- [Async version] Generate for current file
  -- if not info.remote then
  --   -- if info.remote then -- DEBUG: 逆にしてみる NG そりゃそうだ
  --   -- :preview generate {action} {x} {y} {width} {height} {path} {force}
  --   local vifm_cmd = string.format('preview generate %s %d %d %d %d "%s" %s %s', info.action, info.x, info.y, info.width, info.height, info.path, info.force and "true" or "false", "remote")
  --   cnt = cnt + 1
  --   -- vifm_cmd = string.format("echo '%d'", cnt) -- NG 無限ループ
  --   -- vifm_cmd = string.format("!touch '/Users/rio/.cache/vifm/preview/test-%d'", cnt) -- NG 無限ループなのは一緒
  --   -- vifm_cmd = "" -- DEBUG: これだと無限ループしない(＆ちらつかない)。なので、自動的な画面の再描画が原因っぽい。
  --   M.log("info", "vifm_cmd: " .. vifm_cmd, info)
  --   local async_cmd = string.format("sleep %.3f; vifm --server-name %s --remote -c '%s'", config.preview.delay / 1000, M.SERVER_NAME, vifm_cmd)
  --   M.log("info", "async_cmd: " .. async_cmd, info)
  --   vifm.startjob({
  --     cmd = async_cmd,
  --     description = "delayed generate() & show()",
  --   })
  --   M.log("info", "delayed generate() & show() is set.", info)
  --
  --   -- Generate for all files in current dir
  --   local cwd = vifm.currview().cwd
  --   M.log("info", "cwd = '" .. cwd .. "'", info)
  --   info.path = cwd
  --   -- if not info.remote then -- DEBUG: remote 呼び出し時を回避してみたが、そもそも fileviewer 側からの call なら info.remote は nil
  --   M.generate_all(info) -- DEBUG: ここは async にしなくていいのか？ 諸々のチェックで、多少の UI ブロッキングはしているぞ？
  --   -- end
  --   --
  --   --
  --   -- ⭐️⭐️⭐️ むりっぽい。難しすぎる。あとは、bash スクリプトを & で実行するかな。 (ただしキャンセル出来ない？)
  --   -- fileviewer からの関数で、$VIFM_CURR_FILEPATH に保存しておき、それを bash で一致不一致をチェックするか？
  --
  --   -- if info.remote then -- remote として呼び出された時は、ここで REMOTE をオフにする
  --   --   M.REMOTE = false
  --   -- else -- fileviewer から呼び出された場合は、REMOTE をオンにする (上記でasyncコマンドセット済みだから)
  --   --   M.REMOTE = true
  --   -- end
  -- end
  --
  -- M.PREV_PATH = info.path

  -- Generate for all files in current dir
  local cwd = vifm.currview().cwd
  M.log("info", "cwd = '" .. cwd .. "'", info)
  info.path = cwd
  if not info.remote then M.generate_all(info) end

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
    -- vifm.sb.info("info: " .. util.inspect(info)) -- TEST:
    -- Re-format info table
    info.subcmd = "preview"
    info.action = info.command:match("^#" .. M.PLUGIN_NAME .. "#preview (%S+)")
    info.force = false
    info.remote = false -- DEBUG: ほんとにこれ？ async
    -- vifm.sb.info(util.inspect(info))
    preview(info)
  end,
})

vifm.addhandler({
  name = "clear",
  handler = function(info)
    if info.remote then return end -- DEBUG: ほんとにこれ？ async | clear はさぁ、fileviewer からしか呼ばれないのよ。info.remote は nil なの常に。意味なし
    info = {
      subcmd = "clear",
      action = "-",
    }
    clear(info)
  end,
})

-- TODO: NO NEED to set as handler for them
-- vifm.addhandler({
--   name = "refresh",
--   handler = function(info)
--     info = {
--       subcmd = "refresh",
--       action = "-",
--     }
--     refresh(info)
--   end,
-- })
--
-- vifm.addhandler({
--   name = "delete",
--
--   handler = function(info)
--     info = {
--       subcmd = "delete",
--       action = "-",
--     }
--     delete(info)
--   end,
-- })

-- ╭───────────────────────────────────────────────────────────────╮
-- │                      Setup vifm command                       │
-- ╰───────────────────────────────────────────────────────────────╯
-- Purpose:
--   1. To call from keymaps
--   2. To call asynchronously by 'init.lua'-self

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
    -- vifm.sb.info("info: " .. util.inspect(info)) -- TEST:
    if info.subcmd == "generate" then -- Asynchronously called by `fileviewer` in vifmrc
      -- :preview generate {action} {x} {y} {width} {height} {path} {force} {remote}
      --          #1       #2       #3  #4  #5      #6       #7     #8      #9
      info.subcmd = info.argv[1]
      info.action = info.argv[2]
      info.x = info.argv[3]
      info.y = info.argv[4]
      info.width = info.argv[5]
      info.height = info.argv[6]
      info.path = util.unquote(info.argv[7])
      info.force = info.argv[8]
      info.remote = info.argv[9] == "remote" and true or false
      info.tty = M.TTY
      M.generate(info, function() show(info) end)
      -- M.generate(info, function() local a = 1 end)
    elseif info.subcmd == "refresh" then
      info.action = "-"
      refresh(info)
    elseif info.subcmd == "delete" then
      info.action = "-"
      delete(info)
    end
    M.log("command", "(out) preview", info)
  end,
  minargs = 0,
  maxargs = -1,
})

return M
