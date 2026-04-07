return {
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("gitsigns").setup({
                signs = {
                    add          = { text = "▎" },
                    change       = { text = "▎" },
                    delete       = { text = "" },
                    topdelete    = { text = "" },
                    changedelete = { text = "▎" },
                    untracked    = { text = "▎" },
                },
                on_attach = function(bufnr)
                    local gs = package.loaded.gitsigns
                    local map = function(mode, l, r, opts)
                        opts = opts or {}
                        opts.buffer = bufnr
                        vim.keymap.set(mode, l, r, opts)
                    end

                    -- Navegar entre hunks
                    map("n", "]h", gs.next_hunk,  { desc = "Git: next hunk" })
                    map("n", "[h", gs.prev_hunk,  { desc = "Git: prev hunk" })

                    -- Ações sobre hunks
                    map("n", "<leader>hs", gs.stage_hunk,   { desc = "Git: stage hunk" })
                    map("n", "<leader>hr", gs.reset_hunk,   { desc = "Git: reset hunk" })
                    map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Git: undo stage hunk" })
                    map("n", "<leader>hp", gs.preview_hunk, { desc = "Git: preview hunk" })
                    map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, { desc = "Git: blame line" })
                    map("n", "<leader>hd", gs.diffthis,     { desc = "Git: diff this" })

                    -- Stage/reset ficheiro inteiro
                    map("n", "<leader>gS", gs.stage_buffer,  { desc = "Git: stage buffer" })
                    map("n", "<leader>gR", gs.reset_buffer,  { desc = "Git: reset buffer" })

                    -- Toggle blame inline
                    map("n", "<leader>gb", gs.toggle_current_line_blame, { desc = "Git: toggle line blame" })
                end,
            })
        end,
    },
}
