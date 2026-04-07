return {
    {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        event = "InsertEnter",
        config = function()
            require("copilot").setup({
                suggestion = {
                    enabled = true,
                    auto_trigger = true,
                    keymap = {
                        accept = false,        -- Tab é gerido pelo blink.cmp
                        accept_word = "<M-w>",
                        accept_line = "<M-l>",
                        next = "<M-]>",
                        prev = "<M-[>",
                        dismiss = "<C-]>",
                    },
                },
                panel = { enabled = false },
            })

            local copilot_enabled = true
            vim.keymap.set("n", "<leader>ip", function()
                copilot_enabled = not copilot_enabled
                require("copilot.suggestion").toggle_auto_trigger()
                local msg = copilot_enabled and "Copilot enabled ✓" or "Copilot disabled ✗"
                local level = copilot_enabled and vim.log.levels.INFO or vim.log.levels.WARN
                vim.notify(msg, level)
            end, { desc = "Toggle Copilot inline" })
        end,
    },
}
