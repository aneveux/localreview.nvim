describe("localreview.display", function()
  local display

  before_each(function()
    package.loaded["localreview.display"] = nil
    display = require("localreview.display")
  end)

  describe("_relative_time", function()
    it("returns 'just now' for timestamps under 60 seconds ago", function()
      local result = display._relative_time(os.time() - 30)
      assert.are.equal("just now", result)
    end)

    it("returns singular minute for 60 seconds ago", function()
      local result = display._relative_time(os.time() - 60)
      assert.are.equal("1 minute ago", result)
    end)

    it("returns minutes for timestamps under 1 hour", function()
      local result = display._relative_time(os.time() - 300)
      assert.are.equal("5 minutes ago", result)
    end)

    it("returns singular hour for 3600 seconds ago", function()
      local result = display._relative_time(os.time() - 3600)
      assert.are.equal("1 hour ago", result)
    end)

    it("returns hours for timestamps under 1 day", function()
      local result = display._relative_time(os.time() - 7200)
      assert.are.equal("2 hours ago", result)
    end)

    it("returns 'yesterday' for timestamps 24-48 hours ago", function()
      local result = display._relative_time(os.time() - 100000)
      assert.are.equal("yesterday", result)
    end)

    it("returns days for timestamps under 1 week", function()
      local result = display._relative_time(os.time() - 345600)
      assert.are.equal("4 days ago", result)
    end)

    it("returns weeks for timestamps under 1 month", function()
      local result = display._relative_time(os.time() - 1209600)
      assert.are.equal("2 weeks ago", result)
    end)

    it("returns months for timestamps over 1 month", function()
      local result = display._relative_time(os.time() - 5184000)
      assert.are.equal("2 months ago", result)
    end)
  end)

  describe("_format_reviews", function()
    it("formats single review with separator and timestamp", function()
      local reviews = {
        { comment = "Fix this bug", timestamp = os.time() - 120, end_line = nil },
      }
      local lines, highlight_lines, title = display._format_reviews(reviews, 10, "10")
      assert.are.equal("Reviews for line 10 (1)", title)
      assert.is_true(#lines >= 2)
      assert.are.equal("Fix this bug", lines[2])
    end)

    it("includes range in title when reviews have end_line", function()
      local reviews = {
        { comment = "Range comment", timestamp = os.time() - 60, end_line = 15 },
      }
      local lines, highlight_lines, title = display._format_reviews(reviews, 10, "10")
      assert.are.equal("Reviews for lines 10-15 (1)", title)
    end)

    it("formats multiple reviews with blank line separator", function()
      local reviews = {
        { comment = "First", timestamp = os.time() - 60, end_line = nil },
        { comment = "Second", timestamp = os.time() - 120, end_line = nil },
      }
      local lines, _, title = display._format_reviews(reviews, 5, "5")
      assert.are.equal("Reviews for line 5 (2)", title)
      local found_blank = false
      for _, l in ipairs(lines) do
        if l == "" then
          found_blank = true
        end
      end
      assert.is_true(found_blank)
    end)
  end)
end)
