local M = {}

M.ns = vim.api.nvim_create_namespace("localreview")

---@param buf number buffer handle
---@param line number 1-indexed line number
---@param count number number of reviews on this line
---@param is_stale boolean|nil true if any review on this line is stale
function M.set_line_hint(buf, line, count, is_stale)
  local cfg = require("localreview.config").values.virtual_text
  if not cfg.enabled then
    return
  end

  local marks = vim.api.nvim_buf_get_extmarks(buf, M.ns, { line - 1, 0 }, { line - 1, -1 }, {})
  for _, mark in ipairs(marks) do
    vim.api.nvim_buf_del_extmark(buf, M.ns, mark[1])
  end

  local text = count == 1 and "\xF0\x9F\x92\xAC 1 review" or "\xF0\x9F\x92\xAC " .. count .. " reviews"
  local hl = is_stale and cfg.stale_hl_group or cfg.hl_group

  vim.api.nvim_buf_set_extmark(buf, M.ns, line - 1, 0, {
    virt_text = { { text, hl } },
    virt_text_pos = "eol",
  })
end

---@param buf number buffer handle
---@param line number 1-indexed line number
function M.clear_line_hint(buf, line)
  local marks = vim.api.nvim_buf_get_extmarks(buf, M.ns, { line - 1, 0 }, { line - 1, -1 }, {})
  for _, mark in ipairs(marks) do
    vim.api.nvim_buf_del_extmark(buf, M.ns, mark[1])
  end
end

---@param buf number buffer handle
---@param data table|nil review data from storage
---@param stale_lines table|nil map of string line_key -> boolean
function M.render_all(buf, data, stale_lines)
  if not data or not data.reviews then
    return
  end

  vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)

  for line_key, reviews in pairs(data.reviews) do
    if #reviews > 0 then
      local is_stale = stale_lines and stale_lines[line_key] or false
      M.set_line_hint(buf, tonumber(line_key), #reviews, is_stale)
    end
  end
end

---@param buf number buffer handle (0 for current)
---@param line number 1-indexed line number
function M.refresh_line(buf, line)
  if buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end

  local bufpath = vim.api.nvim_buf_get_name(buf)
  local storage = require("localreview.storage")
  local review_file = storage.review_path(bufpath)
  local data = storage.read_reviews(review_file)

  local line_key = tostring(line)
  local reviews = data and data.reviews and data.reviews[line_key]

  if reviews and #reviews > 0 then
    local is_stale = false
    local cfg = require("localreview.config").values
    if cfg.git.track_commit and reviews then
      local git = require("localreview.git")
      local current_sha = git.get_head_sha(bufpath)
      if current_sha then
        for _, entry in ipairs(reviews) do
          if git.is_stale(entry.commit, current_sha) then
            is_stale = true
            break
          end
        end
      end
    end
    M.set_line_hint(buf, line, #reviews, is_stale)
  else
    M.clear_line_hint(buf, line)
  end
end

return M
