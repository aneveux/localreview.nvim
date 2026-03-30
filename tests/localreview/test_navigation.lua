describe("localreview.navigation", function()
  local navigation

  before_each(function()
    package.loaded["localreview.navigation"] = nil
    navigation = require("localreview.navigation")
  end)

  describe("_find_next_in_list", function()
    it("returns the first line after cursor", function()
      local result = navigation._find_next_in_list({ 5, 10, 20 }, 7)
      assert.are.equal(10, result)
    end)

    it("wraps around to first line when cursor is past all lines", function()
      local result = navigation._find_next_in_list({ 5, 10, 20 }, 25)
      assert.are.equal(5, result)
    end)

    it("wraps around when cursor is on the last reviewed line", function()
      local result = navigation._find_next_in_list({ 5, 10, 20 }, 20)
      assert.are.equal(5, result)
    end)

    it("returns nil for empty list", function()
      local result = navigation._find_next_in_list({}, 5)
      assert.is_nil(result)
    end)

    it("returns the immediate next line", function()
      local result = navigation._find_next_in_list({ 1, 2, 3 }, 1)
      assert.are.equal(2, result)
    end)
  end)

  describe("_find_prev_in_list", function()
    it("returns the first line before cursor", function()
      local result = navigation._find_prev_in_list({ 5, 10, 20 }, 15)
      assert.are.equal(10, result)
    end)

    it("wraps around to last line when cursor is before all lines", function()
      local result = navigation._find_prev_in_list({ 5, 10, 20 }, 3)
      assert.are.equal(20, result)
    end)

    it("wraps around when cursor is on the first reviewed line", function()
      local result = navigation._find_prev_in_list({ 5, 10, 20 }, 5)
      assert.are.equal(20, result)
    end)

    it("returns nil for empty list", function()
      local result = navigation._find_prev_in_list({}, 5)
      assert.is_nil(result)
    end)

    it("returns the immediate previous line", function()
      local result = navigation._find_prev_in_list({ 1, 2, 3 }, 3)
      assert.are.equal(2, result)
    end)
  end)
end)
