return {
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        config = function()
            local wk = require("which-key")
            wk.setup({
                delay = 400,
                icons = { rules = false },
            })
            -- Grupos de prefixos para o menu ficar organizado
            wk.add({
                { "<leader>a",  group = "Harpoon" },
                { "<leader>d",  group = "Diagnostics" },
                { "<leader>f",  group = "Find (Telescope)" },
                { "<leader>g",  group = "Git" },
                { "<leader>h",  group = "Git Hunks" },
                { "<leader>i",  group = "AI (Avante)" },
                { "<leader>m",  group = "Markdown" },
                { "<leader>r",  group = "Refactor / Rename" },
                { "<leader>x",  group = "Trouble" },
            })
        end,
    },
}
