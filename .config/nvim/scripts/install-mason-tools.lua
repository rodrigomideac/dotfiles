-- Headless Mason tool installer with per-tool progress, timeout, and error handling.
-- Run with: nvim --headless +"luafile /path/to/install-mason-tools.lua"
--
-- Installs tools directly via mason-registry API (bypassing mason-tool-installer
-- which doesn't work reliably in headless mode).
-- Exits nvim explicitly: qa! on success, cquit 1 on failure/timeout.

local TIMEOUT_SECS = tonumber(vim.env.MASON_TIMEOUT) or 600 -- 10 minutes default

local function log(msg)
  io.write("[mason-install] " .. msg .. "\n")
  io.flush()
end

-- Load the shared tool list
local ok_tools, tools = pcall(require, "config.mason-tools")
if not ok_tools then
  log("ERROR: Failed to load config.mason-tools: " .. tostring(tools))
  vim.cmd("cquit 1")
  return
end

local expected_count = #tools
log("Expected tools: " .. expected_count)

-- Quick pre-check via filesystem (avoids loading mason.nvim when all tools are installed).
local mason_pkg_dir = vim.fn.stdpath("data") .. "/mason/packages/"
local any_missing = false
for _, name in ipairs(tools) do
  if vim.fn.isdirectory(mason_pkg_dir .. name) == 0 then
    any_missing = true
    break
  end
end

if not any_missing then
  log("All tools already installed")
  vim.cmd("qa!")
  return
end

-- Ensure mason.nvim is loaded and set up (it may be lazy-loaded via cmd = "Mason")
require("lazy").load({ plugins = { "mason.nvim" } })

local registry = require("mason-registry")

-- Track results (need_install is set definitively inside the refresh callback)
local need_install = 0
local completed = 0
local failed_count = 0
local failed_tools = {}
local registry_errors = 0
local start_time = vim.uv.now()
local finished = false

local function elapsed()
  return string.format("%.1fs", (vim.uv.now() - start_time) / 1000)
end

local function finish(reason)
  if finished then
    return
  end
  finished = true

  log("")
  if reason == "timeout" then
    log("=== TIMEOUT ===")
    log(string.format("Timed out after %ds. Installed: %d | Failed: %d", TIMEOUT_SECS, completed, failed_count))
  else
    log("=== Installation Complete (" .. reason .. ") ===")
    log(string.format("Installed: %d | Failed: %d | Total time: %s", completed, failed_count, elapsed()))
  end

  if (failed_count + registry_errors) > 0 or reason == "timeout" then
    if #failed_tools > 0 then
      log("Failed tools: " .. table.concat(failed_tools, ", "))
    end
    vim.cmd("cquit 1")
  else
    log("All tools installed successfully")
    vim.cmd("qa!")
  end
end

local function check_done()
  if need_install > 0 and completed + failed_count >= need_install then
    vim.schedule(function()
      finish("all tracked")
    end)
  end
end

-- Registry per-package events for progress tracking
registry:on("package:install:success", function(pkg)
  completed = completed + 1
  log(string.format("[%d/%d] Installed: %s (%s)", completed + failed_count, need_install, pkg.name, elapsed()))
  check_done()
end)

registry:on("package:install:failed", function(pkg, err)
  failed_count = failed_count + 1
  table.insert(failed_tools, pkg.name)
  log(string.format("[%d/%d] FAILED: %s - %s (%s)", completed + failed_count, need_install, pkg.name, tostring(err), elapsed()))
  check_done()
end)

-- Timeout safety net
vim.defer_fn(function()
  finish("timeout")
end, TIMEOUT_SECS * 1000)

-- Refresh registry, then install each tool directly (same approach as LazyVim's
-- mason config at lazyvim/plugins/lsp/init.lua:293-300).
log("Refreshing registry and starting installs...")
registry.refresh(function(success)
  if not success then
    log("ERROR: Registry refresh failed (network issue or no cached registry)")
    vim.cmd("cquit 1")
    return
  end

  local to_install = {}
  for _, name in ipairs(tools) do
    local ok, pkg = pcall(registry.get_package, name)
    if ok then
      if not pkg:is_installed() then
        table.insert(to_install, pkg)
      end
    else
      registry_errors = registry_errors + 1
      table.insert(failed_tools, name)
      log(string.format("WARNING: Package %q not found in registry", name))
    end
  end

  need_install = #to_install
  log(string.format("Confirmed need to install: %d (after registry refresh)", need_install))

  if need_install == 0 then
    finish("all already installed after registry refresh")
    return
  end

  for _, pkg in ipairs(to_install) do
    pkg:install()
  end
end)
