return {
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local harpoon = require("harpoon")
            harpoon:setup({
                settings = {
                    save_on_toggle = true,
                    sync_on_ui_close = true,
                },
            })

            local map = vim.keymap.set

            -- Adicionar ficheiro atual à lista
            map("n", "<leader>a", function()
                harpoon:list():add()
                vim.notify("Harpoon: ficheiro adicionado ✓", vim.log.levels.INFO)
            end, { desc = "Harpoon: add file" })

            -- Abrir o menu (como as tabs do VSCode)
            map("n", "<leader>e", function()
                harpoon.ui:toggle_quick_menu(harpoon:list())
            end, { desc = "Harpoon: quick menu" })

            -- Saltar direto para slot 1-4 com <leader>1..4
            map("n", "<leader>1", function() harpoon:list():select(1) end, { desc = "Harpoon: file 1" })
            map("n", "<leader>2", function() harpoon:list():select(2) end, { desc = "Harpoon: file 2" })
            map("n", "<leader>3", function() harpoon:list():select(3) end, { desc = "Harpoon: file 3" })
            map("n", "<leader>4", function() harpoon:list():select(4) end, { desc = "Harpoon: file 4" })
            map("n", "<leader>5", function() harpoon:list():select(5) end, { desc = "Harpoon: file 5" })

            -- Navegar para o próximo/anterior na lista (Alt+j / Alt+k)
            map("n", "<M-j>", function() harpoon:list():next() end, { desc = "Harpoon: next file" })
            map("n", "<M-k>", function() harpoon:list():prev() end, { desc = "Harpoon: prev file" })
        end,
    },
}
