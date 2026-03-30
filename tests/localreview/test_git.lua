describe("git", function()
  local git = require("localreview.git")

  describe("is_stale", function()
    it("returns false when review_sha is nil", function()
      assert.is_false(git.is_stale(nil, "abc1234"))
    end)

    it("returns false when current_sha is nil", function()
      assert.is_false(git.is_stale("abc1234", nil))
    end)

    it("returns false when SHAs match", function()
      assert.is_false(git.is_stale("abc1234", "abc1234"))
    end)

    it("returns true when SHAs differ", function()
      assert.is_true(git.is_stale("abc1234", "def5678"))
    end)
  end)
end)
