return {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      require("nvim-treesitter.config").setup({
        ensure_installed = {"lua", "javascript", "typescript", "rust"},
        highlight = { enable = true },
        indent = { enable = true }
      })
    end
}