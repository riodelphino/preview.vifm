local M = {}

-- ---@param cmd string
-- ---@return any
-- function M.execute(cmd)
--   local f = io.popen(cmd)
--   if not f then return nil end
--   local ret = f:read("*l")
--   f:close()
--   return ret
-- end

---@param cmd string
---@return table result
function M.execute(cmd)
  local f = io.popen(cmd)
  if not f then return {} end
  local lines = {}
  for line in f:lines() do
    table.insert(lines, line)
  end
  f:close()
  return lines
end

---@param dst table
---@param src table
---@return table merged_table
function M.deep_merge(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" and type(dst[k]) == "table" then
      M.deep_merge(dst[k], v)
    else
      dst[k] = v
    end
  end
  return dst
end

---@param src table
---@return table copied_table
function M.deep_copy(src) return M.deep_merge({}, src) end

---@param t table
---@param indent number?
---@param linebreak boolean?
---@return string expanded_string
function M.inspect(t, indent, linebreak)
  indent = indent or 2
  linebreak = linebreak ~= false -- true is default
  local pad = string.rep("  ", indent)
  local s
  if linebreak then
    s = "{\n"
  else
    s = "{ "
  end
  for k, v in pairs(t) do
    s = s .. pad .. "[" .. tostring(k) .. "]" .. " = "
    if type(v) == "table" then
      s = s .. M.inspect(v, indent + 1, linebreak)
    else
      if type(v) == "string" then
        s = s .. '"' .. tostring(v) .. '"'
      else
        s = s .. tostring(v)
      end
    end
    if linebreak then
      s = s .. ",\n"
    else
      s = s .. ", "
    end
  end
  return s .. pad .. "}"
end

-- Get environment as table
function M.get_environment()
  local env = {
    nvim = os.getenv("NVIM") and true or false,
    tmux = os.getenv("TMUX") and true or false,
  }
  env.terminal = not env.tmux
  return env
end

function M.get_hash(str, hash_cmd)
  local cmd = string.format('printf %%q "%s" | %s', str, hash_cmd)
  local ret = M.execute(cmd)[1]
  return ret:match("^%w+")
end

---@param str string
---@param delimiter string
---@return table splitted
function M.split(str, delimiter)
  local regex = string.format("[^%s]+", delimiter)
  local tbl = {}
  for part in str:gmatch(regex) do
    table.insert(tbl, part)
  end
  return tbl
end

---@param str string
---@return string trimmed
function M.trim(str) return str:match("^%s*(.-)%s*$") end

---@param dir string
---@param patterns string
---@return table files
function M.glob(dir, patterns)
  local pats = {}
  for idx, pat in ipairs(M.split(patterns, ",")) do
    local prefix = idx == 1 and "-name" or "-o -name"
    pat = M.trim(pat)
    local line = string.format("%s '%s'", prefix, pat)
    table.insert(pats, line)
  end
  local criteria = table.concat(pats, " ")
  local cmd = string.format("find '%s' \\( %s \\)", dir, criteria)
  local files = M.execute(cmd)
  return files
end

---@param path string
---@return string? real_path
function M.realpath(path)
  local cmd = string.format('cd "%s" 2>/dev/null && pwd -P', path)
  local ret = M.execute(cmd)[1]
  return ret and ret:gsub("%s+$", "") or path
end

---@param path string
---@return boolean
function M.is_dir(path)
  local cmd = string.format('if [ -d "%s" ]; then echo "true"; else echo "false"; fi', path)
  local ret = M.execute(cmd)[1]
  return ret == "true"
end

---@param path string
---@return number? timestamp
function M.get_mtime(path)
  if vifm.exists(path) then
    local cmd = string.format([[stat -f "%%m" "%s" 2>/dev/null || stat -c "%%Y" "%s" 2>/dev/null]], path, path)
    local ret = M.execute(cmd)[1]
    return tonumber(ret)
  else
    return 0
  end
end

---Replace placeholders
---@param cmd string
---@param info table
---@return string cmd
function M.get_cmd(cmd, info)
  for k, v in pairs(info) do
    cmd = cmd:gsub("%%{" .. k .. "}", tostring(v))
  end
  return cmd
end

---Return current file path in currview
function M.get_current_filepath()
  local view = vifm.currview()
  local entry = view:entry(view.cursor.pos)
  local path = entry.location .. "/" .. entry.name
  return path
end

---Un-quote "" or ''
function M.unquote(str) return (str:gsub('^["\'](.*)["\'"]$', "%1")) end

function M.get_cache_filepath(path, cache_dir, cache_ext, hash_cmd)
  local hash = M.get_hash(path, hash_cmd)
  return string.format("%s/%s.%s", cache_dir, hash, cache_ext)
end

return M
