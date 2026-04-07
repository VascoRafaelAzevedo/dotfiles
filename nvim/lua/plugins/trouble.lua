return {
    {
        "folke/trouble.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        cmd = "Trouble",
        keys = {
            { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>",                        desc = "Trouble: diagnostics (workspace)" },
            { "<leader>xf", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",           desc = "Trouble: diagnostics (file)" },
            { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>",                desc = "Trouble: symbols" },
            { "<leader>xl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "Trouble: LSP references/defs" },
            { "<leader>xq", "<cmd>Trouble qflist toggle<cr>",                             desc = "Trouble: quickfix" },
        },
        config = function()
            require("trouble").setup({ use_diagnostic_signs = true })
        end,
    },
}
