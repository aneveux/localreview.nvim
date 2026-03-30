return require("telescope").register_extension({
  exports = {
    localreview = require("localreview.telescope").picker,
  },
})
