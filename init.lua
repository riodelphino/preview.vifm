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

---@param subcmd string
---@param category string
---@param message string
function M.log(subcmd, category, message)
  local subcmd_len = 8
  local category_len = 15
  if config.log.enabled then
    local f = assert(io.open(config.log.path, "a"))
    subcmd = string.format("%-" .. subcmd_len .. "s", subcmd)
    category = string.format("%-" .. category_len .. "s", category)
    f:write(string.format("[ %s ] %s: %s\n", subcmd, category, message))
    f:close()
  end
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
    local ctx = {
      cache_dir = config.cache.dir,
      source = path,
      hash = util.get_hash(path, hash_cmd),
    }
    -- vifm.sb.info("action_name: " .. action_name) -- DEBUG:
    -- vifm.sb.info(util.inspect(config)) -- DEBUG:
    local preview_path = config.actions[action_name].generate.preview_path(ctx)
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
    local ctx = {
      cache_dir = config.cache.dir,
      source = path,
      hash = util.get_hash(path, hash_cmd),
    }
    local preview_path = config.actions[action_name].generate.preview_path(ctx)
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

---@param action_name string
---@param source string
---@param force boolean?
---@param cb function?
function M.generate_preview(action_name, source, force, cb)
  -- 対象: 単一ファイル
  -- すでにプレビューファイルが存在 -> そのままプレビュー表示
  -- なければプレビュー画像を生成 -> プレビュー表示

  -- Get generate command
  local hash_cmd = config.cache.hash_cmd
  local action = config.actions[action_name]
  local args = util.deep_copy(action.generate.args)
  local ctx = {
    cache_dir = config.cache.dir,
    source = source,
    hash = util.get_hash(source, hash_cmd),
  }
  args.out = action.generate.preview_path(ctx)
  args.path = source

  -- Check if generation is necessary
  local preview_exists = vifm.exists(args.out)
  if preview_exists and not force then -- TODO: Add state check ?
    -- vifm.sb.info("Skipped action_name:" .. source)
    if cb then cb() end
    return
  end

  local preview_mtime = util.get_mtime(args.out)
  local source_mtime = util.get_mtime(source)
  preview_mtime = preview_mtime or 0
  local preview_older = preview_mtime < source_mtime
  if not preview_older and not force then return end

  local cmd = util.get_cmd(action.generate.cmd(args), args)

  if cmd == "" then return end

  -- Generate
  -- vifm.sb.info("cmd: " .. cmd) -- DEBUG:
  util.execute(cmd .. " >/dev/null 2>&1 &") -- DEBUG:
  -- if action_name == "video" then vifm.sb.info(cmd) end
  if cb then cb() end
end

---Generate previews for all files in dir
---@param cwd string
---@param ctx table
---@param force boolean?
function M.generate_preview_all(cwd, ctx, force)
  for action_name, action in pairs(config.actions) do
    if force then M.set_state(cwd, action_name, "none") end
    -- vifm.sb.info("force: " .. (force and "true" or "false"))
    local state = M.get_state(cwd, action_name)
    -- vifm.sb.info("state: " .. state) -- DEBUG:
    if state == "locked" or state == "done" then return end -- Exit if locked or done
    M.set_state(cwd, action_name, "locked")
    local files = util.glob(cwd, action.patterns)
    -- vifm.sb.info(util.inspect(files)) -- DEBUG:
    -- Loop for the all pattern matched files
    for _, file in ipairs(files) do
      if util.realpath(file) ~= util.realpath(ctx.path) then -- Skip current file
        M.generate_preview(action_name, file, force, nil)
      end
    end
    M.set_state(cwd, action_name, "done")
  end
end

-- clear command
local function clear(ctx)
  -- local ctx_clear = {
  --   file = preview_path,
  --   px = 2,
  --   py = 10,
  --   pw = 20,
  --   ph = 15,
  --   tty = "tty019",
  -- }
  ctx.tty = os.getenv("VIFM_PREVIEW_TTY")
  local cmd = config.command.clear
  cmd = util.get_cmd(cmd, ctx)
  util.execute(cmd)
  -- vifm.sb.info("clear: " .. cmd_clear)
end

local function show(ctx)
  local view = vifm.currview()
  local entry = view:entry(view.cursor.pos)
  local curr_path = entry.location .. "/" .. entry.name
  -- vifm.sb.info(util.inspect(entry))
  if util.realpath(ctx.path) ~= curr_path then -- Skip if current entry is changed
    vifm.sb.info("skip show for " .. entry.name)
    return
  end

  ctx.tty = os.getenv("VIFM_PREVIEW_TTY")
  local cmd = config.command.show
  local env = util.get_environment()
  if env.nvim then
    ctx.x = ctx.x + os.getenv("VIFM_PREVIEW_WIN_X") + os.getenv("VIFM_PREVIEW_WIN_BORDER_WIDTH")
    ctx.y = ctx.y + os.getenv("VIFM_PREVIEW_WIN_Y") + os.getenv("VIFM_PREVIEW_WIN_BORDER_WIDTH")
  end
  -- cmd = util.get_cmd(cmd .. " &", ctx)
  cmd = util.get_cmd(cmd, ctx)
  util.execute(cmd)
end

local function refresh(ctx)
  -- TODO: Add refresh code
end

local function delete(ctx)
  -- TODO: Add delete code
end

local function preview(ctx)
  ctx.tty = os.getenv("VIFM_PREVIEW_TTY")

  local action_name = ctx.command:match("^#" .. M.PLUGIN_NAME .. "#preview (%S+)")
  -- vifm.sb.info(action .. ":\n" .. util.inspect(ctx))
  local action = config.actions[action_name]
  if not action then
    local mes = string.format("%s action is not defined.", action_name)
    vifm.sb.error(mes)
    return
  end
  -- vifm.sb.info(table.concat(action.patterns, ","))

  -- Generate for current file
  M.generate_preview(action_name, ctx.path, false, function() show(ctx) end)

  -- Generate for all files in current dir
  local cwd = vifm.currview().cwd
  M.generate_preview_all(cwd, ctx)
end

vifm.addhandler({
  name = "preview",
  handler = function(ctx) preview(ctx) end,
})

vifm.addhandler({
  name = "clear",
  handler = function(ctx) clear(ctx) end,
})

vifm.addhandler({
  name = "refresh",
  handler = function(ctx) refresh(ctx) end,
})

vifm.addhandler({
  name = "delete",
  handler = function(ctx) delete(ctx) end,
})

return M
