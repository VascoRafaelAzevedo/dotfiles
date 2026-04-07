return {
    {
        "yetone/avante.nvim",
        event = "VeryLazy",
        version = false, -- usa sempre a versão mais recente
        build = "make",
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "stevearc/dressing.nvim",
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-tree/nvim-web-devicons",
            "zbirenbaum/copilot.lua",
            "MeanderingProgrammer/render-markdown.nvim",
        },
        opts = {
            provider = "copilot",
            providers = {
                copilot = {
                    model = "gpt-4o", -- muda aqui: gpt-4o | claude-3.5-sonnet | o3-mini
                },
            },
            -- Comportamento do painel
            windows = {
                position = "right",
                width = 35, -- percentagem
                wrap = true,
            },
            -- Keymaps
            mappings = {
                ask            = "<leader>ii",  -- abrir chat / fazer pergunta
                edit           = "<leader>ie",  -- edição inline (seleciona código antes)
                refresh        = "<leader>ir",  -- re-gerar última resposta
                focus          = "<leader>if",  -- focar o painel
                toggle = {
                    default    = "<leader>it",  -- mostrar/esconder painel
                    debug      = "<leader>id",
                    hint       = "<leader>ih",
                },
                -- Aceitar/rejeitar diffs
                diff = {
                    ours       = "co",          -- aceita a tua versão
                    theirs     = "ct",          -- aceita a versão do avante
                    both       = "cb",          -- aceita as duas
                    next       = "]x",          -- próximo diff
                    prev       = "[x",          -- diff anterior
                },
                -- Adicionar ficheiros ao contexto
                files = {
                    add_current = "<leader>ia", -- adiciona o ficheiro atual ao contexto
                },
            },
        },
        config = function(_, opts)
            require("avante").setup(opts)

            vim.keymap.set("n", "<leader>im", function()
                -- Busca os modelos disponíveis diretamente à API do Copilot
                local ok, provider = pcall(require, "avante.providers")
                if not ok then
                    vim.notify("Avante: provider não carregado ainda", vim.log.levels.WARN)
                    return
                end

                local raw = provider.copilot:list_models()
                if not raw or #raw == 0 then
                    vim.notify("Avante: sem modelos disponíveis", vim.log.levels.WARN)
                    return
                end

                -- Constrói a lista de display com nome legível → id
                local display = {}
                local id_map  = {}
                for _, m in ipairs(raw) do
                    local label = (m.display_name or m.id) .. "  [" .. m.id .. "]"
                    table.insert(display, label)
                    id_map[label] = m.id
                end

                vim.ui.select(display, {
                    prompt = "Avante › modelo:",
                }, function(choice)
                    if choice then
                        local model_id = id_map[choice]
                        require("avante.config").override({
                            providers = { copilot = { model = model_id } },
                        })
                        vim.notify("Avante: " .. model_id, vim.log.levels.INFO)
                    end
                end)
            end, { desc = "Avante: switch model" })
        end,
    },
}
