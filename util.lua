local M = {}

---@param cmd string
---@return any
function M.execute(cmd)
  local f = io.popen(cmd)
  if not f then return nil end
  local ret = f:read("*l")
  f:close()
  return ret
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
---@return string expanded_string
function M.inspect(t, indent)
  indent = indent or 2
  local pad = string.rep("  ", indent)
  local s = "{\n"
  for k, v in pairs(t) do
    s = s .. pad .. "  [" .. tostring(k) .. "] = "
    if type(v) == "table" then
      s = s .. M.inspect(v, indent + 1)
    else
      s = s .. tostring(v)
    end
    s = s .. ",\n"
  end
  return s .. pad .. "}"
end

-- WORKS
-- function M.get_hash(str)
--   local f = io.popen("printf %q " .. str .. " | shasum")
--   local out = f:read("*l")
--   f:close()
--   return out:match("^%w+")
-- end

-- ERROR
-- ---@param str string
-- ---@param hash_cmd string
-- ---@return string? hash
-- function M.get_hash(str, hash_cmd)
--   local cmd = string.format('printf %q "%s" | %s', str, hash_cmd)
--   local ret = vifm.run({ cmd = cmd, stdout = true })
--   return ret and ret:match("^%w+") or nil
-- end

-- ERROR
-- ---@param str string
-- ---@param hash_cmd string
-- ---@return string? hash
-- function M.get_hash(str, hash_cmd)
--   -- local cmd = string.format("printf %s | %s", str, hash_cmd)
--   local cmd = string.format('printf %q "%s" | %s', str, str, hash_cmd)
--   -- local ret = vifm.run({ cmd = cmd, stdout = true })
--   local ret = vifm.run({ cmd = cmd }) -- DEBUG: stdout 消してみた
--   return ret and ret:match("^%w+") or nil
-- end

-- function M.get_hash(str, hash_cmd)
--   local cmd = string.format('printf "%s" | %s', str:gsub('"', '\\"'), hash_cmd)
--   -- local out = vifm.run({ cmd = cmd, stdout = true })
--   -- local out = vifm.run({ cmd = cmd .. " >/dev/null 2>&1", stdout = true })
--   local ret = vifm.run({ cmd = cmd, stdout = true })
--   return ret and ret:match("^%w+")
-- end

function M.get_hash(str, hash_cmd)
  local cmd = string.format('printf %%q "%s" | %s', str, hash_cmd)
  local ret = M.execute(cmd)
  return ret:match("^%w+")
end

-- function M.get_hash(str, hash_cmd)
--   local safe = str:gsub('"', '\\"')
--   local cmd = string.format('echo "%s" | %s', safe, hash_cmd)
--   local ret = vifm.run({ cmd = cmd, stdout = true })
--   return ret and ret:match("^%w+")
-- end

---@param dir string
---@param patterns table
---@return table files
function M.glob(dir, patterns)
  local result = {}
  for _, pat in ipairs(patterns) do
    -- local cmd = string.format('ls -1 "%s/%s" 2>/dev/null', dir, pat)
    local cmd = string.format('sh -c \'ls -1 "$1"/%s 2>/dev/null\' _ "%s"', pat, dir)
    local f = io.popen(cmd)
    for line in f:lines() do
      table.insert(result, line)
    end
    f:close()
  end
  return result
end

---@param path string
---@return string? real_path
function M.realpath(path)
  local cmd = string.format('cd "%s" 2>/dev/null && pwd -P', path)
  local ret = M.execute(cmd)
  return ret and ret:gsub("%s+$", "") or path
end

---@param path string
---@return boolean
function M.is_dir(path)
  local cmd = string.format('[ -d "%s" ]', path)
  local ok = M.execute(cmd)
  return ok == true or ok == 0
end

---@param path string
---@return number? timestamp
function M.get_mtime(path)
  local cmd = string.format([[stat -f "%%m" "%s" 2>/dev/null || stat -c "%%Y" "%s" 2>/dev/null]], path, path)
  local ret = M.execute(cmd)
  return tonumber(ret)
end

---Replace placeholders
---@param cmd string
---@param ctx table
---@return string cmd
function M.get_cmd(cmd, ctx)
  for k, v in pairs(ctx) do
    cmd = cmd:gsub("%%{" .. k .. "}", tostring(v))
  end
  return cmd
end
return M
