local M = {}

---@return number[] sorted 1-indexed line numbers with reviews on disk
local function storage_fallback_lines()
  local bufpath = vim.api.nvim_buf_get_name(0)
  if bufpath == "" or vim.bo.buftype ~= "" then
    return {}
  end
  local storage = require("localreview.storage")
  local data = storage.read_reviews(storage.review_path(bufpath))
  if not data or not data.reviews then
    return {}
  end
  local lines = {}
  for key, reviews in pairs(data.reviews) do
    if #reviews > 0 then
      lines[#lines + 1] = tonumber(key)
    end
  end
  table.sort(lines)
  return lines
end

---@param sorted_lines number[] sorted 1-indexed line numbers
---@param cursor_line number 1-indexed cursor position
---@return number|nil target line (1-indexed) or nil
local function find_next_in_list(sorted_lines, cursor_line)
  for _, l in ipairs(sorted_lines) do
    if l > cursor_line then
      return l
    end
  end
  return sorted_lines[1]
end

---@param sorted_lines number[] sorted 1-indexed line numbers
---@param cursor_line number 1-indexed cursor position
---@return number|nil target line (1-indexed) or nil
local function find_prev_in_list(sorted_lines, cursor_line)
  for i = #sorted_lines, 1, -1 do
    if sorted_lines[i] < cursor_line then
      return sorted_lines[i]
    end
  end
  return sorted_lines[#sorted_lines]
end

function M.next_review()
  local buf = vim.api.nvim_get_current_buf()
  local ns = require("localreview.virtual_text").ns
  local cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1

  local marks = vim.api.nvim_buf_get_extmarks(buf, ns, { cursor_row + 1, 0 }, -1, { limit = 1 })
  if #marks == 0 then
    marks = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { limit = 1 })
  end

  if #marks > 0 then
    vim.api.nvim_win_set_cursor(0, { marks[1][2] + 1, 0 })
    return
  end

  local fallback = storage_fallback_lines()
  if #fallback > 0 then
    local cursor_line = cursor_row + 1
    local target = find_next_in_list(fallback, cursor_line)
    if target then
      vim.api.nvim_win_set_cursor(0, { target, 0 })
      return
    end
  end

  vim.notify("[localreview] No reviews in this file", vim.log.levels.WARN)
end

function M.prev_review()
  local buf = vim.api.nvim_get_current_buf()
  local ns = require("localreview.virtual_text").ns
  local cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1

  local marks = vim.api.nvim_buf_get_extmarks(buf, ns, { cursor_row - 1, 0 }, 0, { limit = 1 })
  if #marks == 0 then
    marks = vim.api.nvim_buf_get_extmarks(buf, ns, -1, 0, { limit = 1 })
  end

  if #marks > 0 then
    vim.api.nvim_win_set_cursor(0, { marks[1][2] + 1, 0 })
    return
  end

  local fallback = storage_fallback_lines()
  if #fallback > 0 then
    local cursor_line = cursor_row + 1
    local target = find_prev_in_list(fallback, cursor_line)
    if target then
      vim.api.nvim_win_set_cursor(0, { target, 0 })
      return
    end
  end

  vim.notify("[localreview] No reviews in this file", vim.log.levels.WARN)
end

M._find_next_in_list = find_next_in_list
M._find_prev_in_list = find_prev_in_list

return M
