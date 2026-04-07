return {
    "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
    config = function()
        require("lsp_lines").setup()

        -- Desativa o virtual text padrão do Neovim para não duplicar mensagens
        vim.diagnostic.config({ virtual_text = false })

        -- Toggle: <leader>l liga/desliga lsp_lines
        vim.keymap.set("n", "<leader>l", function()
            local config = vim.diagnostic.config() or {}
            if config.virtual_lines then
                vim.diagnostic.config({ virtual_lines = false, virtual_text = true })
            else
                vim.diagnostic.config({ virtual_lines = true, virtual_text = false })
            end
        end, { desc = "Toggle lsp_lines" })
    end,
}
