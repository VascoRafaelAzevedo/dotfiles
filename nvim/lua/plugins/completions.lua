return {
    {
        "saghen/blink.cmp",
        version = "*",
        opts = {
            keymap = {
                preset = "none",
                -- Tab: aceita sugestão do Copilot (tem prioridade total)
                ["<Tab>"] = {
                    function(_)
                        local ok, suggestion = pcall(require, "copilot.suggestion")
                        if ok and suggestion.is_visible() then
                            suggestion.accept()
                            return true
                        end
                    end,
                    "fallback",
                },
                -- Enter: aceita item selecionado do blink
                ["<CR>"]      = { "accept", "fallback" },
                -- Ctrl+n / Ctrl+p: navegar no menu do blink
                ["<C-n>"]     = { "select_next", "show", "fallback" },
                ["<C-p>"]     = { "select_prev", "show", "fallback" },
                -- Ctrl+Space: forçar abertura do menu blink
                ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
                -- Ctrl+e: fechar menu blink
                ["<C-e>"]     = { "hide", "fallback" },
            },
            appearance = {
                nerd_font_variant = "mono",
            },
            sources = {
                default = { "lsp", "path", "snippets", "buffer" },
            },
            completion = {
                documentation = { auto_show = true, auto_show_delay_ms = 200 },
                list = { selection = { preselect = false, auto_insert = false } },
            },
        },
    },
}
