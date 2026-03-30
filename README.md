# localreview.nvim

Annotate code with review comments directly in Neovim. Like GitHub PR reviews, but local, offline, and stored as JSON files alongside the code.

No external dependencies. Pure Lua + Neovim API.

## Features

- **Line & range annotations** -- annotate a single line or a visual selection
- **Floating window viewer** -- see all reviews on the current line with timestamps and git info
- **Virtual text hints** -- inline indicators showing review count per line
- **Staleness detection** -- reviews track the git commit they were created on and flag when HEAD moves
- **Navigation** -- jump between reviewed lines with `]r` / `[r` (wraps around)
- **Telescope integration** -- search all reviews across the project (optional, telescope not required)
- **File-local storage** -- reviews stored as hidden JSON files next to the source, easy to gitignore or share

## Requirements

- Neovim >= 0.9
- Optional: [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) for project-wide search

## Installation

### lazy.nvim

```lua
{
  "antoine/localreview.nvim",
  config = function()
    require("localreview").setup()
  end,
}
```

### Other plugin managers

Clone or add this repo to your runtimepath, then call:

```lua
require("localreview").setup()
```

## Keybindings

| Key | Mode | Action |
|-----|------|--------|
| `<leader>ra` | n, v | Annotate current line or visual selection |
| `<leader>rv` | n | View reviews on current line |
| `<leader>rd` | n | Delete review on current line |
| `]r` | n | Jump to next review |
| `[r` | n | Jump to previous review |
| `<leader>rt` | n | Open Telescope review picker |

To disable all default keybindings:

```lua
require("localreview").setup({ keys = false })
```

## Commands

| Command | Description |
|---------|-------------|
| `:LocalReviewAnnotate` | Add review (supports `:'<,'>LocalReviewAnnotate` for ranges) |
| `:LocalReviewView` | View reviews on current line |
| `:LocalReviewDelete` | Delete review on current line |
| `:LocalReviewNext` | Jump to next review |
| `:LocalReviewPrev` | Jump to previous review |
| `:LocalReviewTelescope` | Telescope picker (requires telescope.nvim) |

## Configuration

All options with defaults:

```lua
require("localreview").setup({
  keys = {
    annotate = "<leader>ra",
    view = "<leader>rv",
    delete = "<leader>rd",
    next_review = "]r",
    prev_review = "[r",
    telescope = "<leader>rt",
  },
  virtual_text = {
    enabled = true,
    hl_group = "Comment",
    stale_hl_group = "LocalReviewStale",
  },
  git = {
    track_commit = true,
  },
})
```

## Telescope Extension

Load the extension after telescope:

```lua
require("telescope").load_extension("localreview")
```

Then use `:Telescope localreview` or the `<leader>rt` keybinding.

## Storage Format

Reviews are stored as hidden JSON files next to each source file:

```
foo.lua  ->  .foo.lua.reviews.json
```

To ignore review files in version control:

```gitignore
*.reviews.json
```

To share reviews with your team, commit them instead.

## Known Limitations

- **Line drift**: Reviews are stored by line number. Within a session, virtual text tracks edits (insertions/deletions above a review move the indicator). However, when you reopen the file, reviews appear at their **original stored line numbers** because the JSON file is not updated as lines shift. If you add 10 lines above a review, it will point at the wrong line on next open. This is a known trade-off for file-local, dependency-free storage.

## Development

```bash
# Install test dependency
make deps

# Run tests
make test

# Format code
make format
```

## License

MIT
