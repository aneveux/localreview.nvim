local annotations = require("localreview.annotations")
local virtual_text = require("localreview.virtual_text")

describe("annotations module structure", function()
  it("exports annotate function", function()
    assert.is_function(annotations.annotate)
  end)

  it("exports delete_review function", function()
    assert.is_function(annotations.delete_review)
  end)

  it("exports annotate_range_from_lines function", function()
    assert.is_function(annotations.annotate_range_from_lines)
  end)
end)

describe("virtual_text module", function()
  it("creates localreview namespace", function()
    assert.is_number(virtual_text.ns)
    assert.equals(vim.api.nvim_create_namespace("localreview"), virtual_text.ns)
  end)
end)

describe("virtual_text.set_line_hint", function()
  local buf
  local config

  before_each(function()
    package.loaded["localreview.config"] = nil
    config = require("localreview.config")
    config.setup({})
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "line1", "line2", "line3" })
  end)

  after_each(function()
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("sets extmark on correct line", function()
    virtual_text.set_line_hint(buf, 2, 1)
    local marks = vim.api.nvim_buf_get_extmarks(buf, virtual_text.ns, { 1, 0 }, { 1, -1 }, {})
    assert.equals(1, #marks)
  end)

  it("clears previous extmark before setting new one", function()
    virtual_text.set_line_hint(buf, 2, 1)
    virtual_text.set_line_hint(buf, 2, 3)
    local marks = vim.api.nvim_buf_get_extmarks(buf, virtual_text.ns, { 1, 0 }, { 1, -1 }, {})
    assert.equals(1, #marks)
  end)

  it("formats singular review count", function()
    virtual_text.set_line_hint(buf, 1, 1)
    local marks = vim.api.nvim_buf_get_extmarks(buf, virtual_text.ns, { 0, 0 }, { 0, -1 }, { details = true })
    assert.equals(1, #marks)
    local virt_text = marks[1][4].virt_text[1][1]
    assert.truthy(virt_text:find("1 review"))
    assert.is_nil(virt_text:find("1 reviews"))
  end)

  it("formats plural review count", function()
    virtual_text.set_line_hint(buf, 1, 3)
    local marks = vim.api.nvim_buf_get_extmarks(buf, virtual_text.ns, { 0, 0 }, { 0, -1 }, { details = true })
    assert.equals(1, #marks)
    local virt_text = marks[1][4].virt_text[1][1]
    assert.truthy(virt_text:find("3 reviews"))
  end)

  it("respects virtual_text.enabled = false", function()
    config.values.virtual_text.enabled = false
    virtual_text.set_line_hint(buf, 1, 1)
    local marks = vim.api.nvim_buf_get_extmarks(buf, virtual_text.ns, { 0, 0 }, { 0, -1 }, {})
    assert.equals(0, #marks)
    config.values.virtual_text.enabled = true
  end)
end)

describe("virtual_text.clear_line_hint", function()
  local buf

  before_each(function()
    package.loaded["localreview.config"] = nil
    local config = require("localreview.config")
    config.setup({})
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "line1", "line2", "line3" })
  end)

  after_each(function()
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("removes extmark from line", function()
    virtual_text.set_line_hint(buf, 2, 1)
    local marks_before = vim.api.nvim_buf_get_extmarks(buf, virtual_text.ns, { 1, 0 }, { 1, -1 }, {})
    assert.equals(1, #marks_before)

    virtual_text.clear_line_hint(buf, 2)
    local marks_after = vim.api.nvim_buf_get_extmarks(buf, virtual_text.ns, { 1, 0 }, { 1, -1 }, {})
    assert.equals(0, #marks_after)
  end)
end)

describe("virtual_text.render_all", function()
  local buf

  before_each(function()
    package.loaded["localreview.config"] = nil
    local config = require("localreview.config")
    config.setup({})
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "line1", "line2", "line3" })
  end)

  after_each(function()
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("renders hints for all review lines", function()
    local data = {
      reviews = {
        ["1"] = { { comment = "test", timestamp = 123 } },
        ["3"] = { { comment = "test2", timestamp = 456 }, { comment = "test3", timestamp = 789 } },
      },
    }
    virtual_text.render_all(buf, data)

    local marks_line1 = vim.api.nvim_buf_get_extmarks(buf, virtual_text.ns, { 0, 0 }, { 0, -1 }, {})
    local marks_line3 = vim.api.nvim_buf_get_extmarks(buf, virtual_text.ns, { 2, 0 }, { 2, -1 }, {})
    assert.equals(1, #marks_line1)
    assert.equals(1, #marks_line3)
  end)

  it("skips nil data gracefully", function()
    assert.has_no.errors(function()
      virtual_text.render_all(buf, nil)
    end)
  end)
end)
