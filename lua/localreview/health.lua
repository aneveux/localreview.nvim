local M = {}

function M.check()
  vim.health.start("localreview")

  -- Check Neovim version
  if vim.fn.has("nvim-0.9") == 1 then
    vim.health.ok("Neovim >= 0.9")
  else
    vim.health.error("Neovim >= 0.9 required", { "Update Neovim to 0.9 or later" })
  end

  -- Check git availability
  local git_ok = vim.fn.executable("git") == 1
  if git_ok then
    vim.health.ok("git found")
  else
    local cfg = require("localreview.config").values
    if cfg.git.track_commit then
      vim.health.warn("git not found — staleness detection will be disabled", {
        "Install git or set git.track_commit = false",
      })
    else
      vim.health.info("git not found (not required — git.track_commit is disabled)")
    end
  end

  -- Check telescope (optional)
  local has_telescope = pcall(require, "telescope")
  if has_telescope then
    vim.health.ok("telescope.nvim found (optional)")
  else
    vim.health.info("telescope.nvim not found — :LocalReviewTelescope will be unavailable (optional)")
  end
end

return M
