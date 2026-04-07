return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  lazy = false,
  opts = {
    file_types = { "markdown", "Avante" },
    render_modes = { "n", "c", "i" },
  },
  config = function(_, opts)
    require("render-markdown").setup(opts)

    local map = vim.keymap.set

    -- Toggle inline render on/off
    map("n", "<leader>mv", function()
      require("render-markdown").toggle()
    end, { desc = "Markdown: toggle inline render" })

    -- Enable inline render
    map("n", "<leader>me", function()
      require("render-markdown").enable()
    end, { desc = "Markdown: enable inline render" })

    -- Disable inline render
    map("n", "<leader>md", function()
      require("render-markdown").disable()
    end, { desc = "Markdown: disable inline render" })
  end,
}
