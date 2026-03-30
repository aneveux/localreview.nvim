local M = {}

local float_state = { win = nil, buf = nil }

function M.close_float()
  if float_state.win and vim.api.nvim_win_is_valid(float_state.win) then
    vim.api.nvim_win_close(float_state.win, true)
  end
  if float_state.buf and vim.api.nvim_buf_is_valid(float_state.buf) then
    vim.api.nvim_buf_delete(float_state.buf, { force = true })
  end
  float_state.win = nil
  float_state.buf = nil
end

---@param timestamp number os.time() value
---@return string human-friendly relative time
local function relative_time(timestamp)
  local diff = os.time() - timestamp
  if diff < 60 then
    return "just now"
  end
  if diff < 3600 then
    local mins = math.floor(diff / 60)
    return mins == 1 and "1 minute ago" or mins .. " minutes ago"
  end
  if diff < 86400 then
    local hours = math.floor(diff / 3600)
    return hours == 1 and "1 hour ago" or hours .. " hours ago"
  end
  if diff < 172800 then
    return "yesterday"
  end
  if diff < 604800 then
    return math.floor(diff / 86400) .. " days ago"
  end
  if diff < 2592000 then
    local weeks = math.floor(diff / 604800)
    return weeks == 1 and "1 week ago" or weeks .. " weeks ago"
  end
  local months = math.floor(diff / 2592000)
  return months == 1 and "1 month ago" or months .. " months ago"
end

---@param reviews table[] list of review entries
---@param line number cursor line (1-indexed)
---@param line_key string the start line key from storage
---@param current_sha string|nil current HEAD SHA
---@return string[] lines, number[] highlight_lines, string title
local function format_reviews(reviews, line, line_key, current_sha)
  local lines = {}
  local highlight_lines = {}

  local has_range = false
  local range_end = nil
  for _, entry in ipairs(reviews) do
    if entry.end_line then
      has_range = true
      if not range_end or entry.end_line > range_end then
        range_end = entry.end_line
      end
    end
  end

  local title
  if has_range then
    title = "Reviews for lines " .. line_key .. "-" .. range_end .. " (" .. #reviews .. ")"
  else
    title = "Reviews for line " .. line_key .. " (" .. #reviews .. ")"
  end

  lines[#lines + 1] = string.rep("\xe2\x94\x80", 40)

  for i, entry in ipairs(reviews) do
    if i > 1 then
      lines[#lines + 1] = ""
    end
    lines[#lines + 1] = entry.comment
    local ts_line = relative_time(entry.timestamp)
    if entry.commit then
      local short_sha = entry.commit:sub(1, 7)
      if current_sha and entry.commit ~= current_sha then
        ts_line = ts_line .. "  [stale \xe2\x80\x94 " .. short_sha .. "]"
      else
        ts_line = ts_line .. "  [" .. short_sha .. "]"
      end
    end
    lines[#lines + 1] = ts_line
    highlight_lines[#highlight_lines + 1] = #lines - 1
  end

  return lines, highlight_lines, title
end

function M.view_reviews()
  local storage = require("localreview.storage")
  local bufpath = storage.get_buf_filepath()
  if not bufpath then
    return
  end

  local line = vim.api.nvim_win_get_cursor(0)[1]
  local review_file = storage.review_path(bufpath)
  local data = storage.read_reviews(review_file)

  if not data or not data.reviews then
    vim.notify("[localreview] No reviews on this line", vim.log.levels.WARN)
    return
  end

  local collected = {}
  local match_key = tostring(line)
  local actual_start_key = match_key

  if data.reviews[match_key] then
    for _, entry in ipairs(data.reviews[match_key]) do
      collected[#collected + 1] = entry
    end
  end

  for key, entries in pairs(data.reviews) do
    local start = tonumber(key)
    if start and key ~= match_key then
      for _, entry in ipairs(entries) do
        if entry.end_line then
          if line >= start and line <= entry.end_line then
            collected[#collected + 1] = entry
            if tonumber(actual_start_key) > start then
              actual_start_key = key
            end
          end
        end
      end
    end
  end

  if #collected == 0 then
    vim.notify("[localreview] No reviews on this line", vim.log.levels.WARN)
    return
  end

  M.close_float()

  local current_sha = nil
  local cfg = require("localreview.config").values
  if cfg.git.track_commit then
    current_sha = require("localreview.git").get_head_sha(bufpath)
  end

  local lines, highlight_lines, title = format_reviews(collected, line, actual_start_key, current_sha)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  for _, hl_line in ipairs(highlight_lines) do
    vim.api.nvim_buf_add_highlight(buf, -1, "Comment", hl_line, 0, -1)
  end

  local content_width = 1
  for _, l in ipairs(lines) do
    local w = vim.fn.strdisplaywidth(l)
    if w > content_width then
      content_width = w
    end
  end
  local width = math.min(math.max(content_width, 1), 60)
  local height = math.min(math.max(#lines, 1), 20)

  local space_below = vim.api.nvim_win_get_height(0) - vim.fn.winline()
  local anchor, row
  if space_below >= height + 2 then
    anchor = "NW"
    row = 1
  else
    anchor = "SW"
    row = 0
  end

  local win = vim.api.nvim_open_win(buf, false, {
    relative = "cursor",
    row = row,
    col = 0,
    width = width,
    height = height,
    border = "rounded",
    focusable = false,
    style = "minimal",
    title = " " .. title .. " ",
    title_pos = "center",
  })

  float_state.win = win
  float_state.buf = buf

  vim.schedule(function()
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufLeave" }, {
      once = true,
      callback = function()
        M.close_float()
      end,
    })
  end)
end

M._relative_time = relative_time
M._format_reviews = format_reviews

return M
