return {
    {
        "goolord/alpha-nvim",
        event = "VimEnter",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            local alpha   = require("alpha")
            local dashboard = require("alpha.themes.dashboard")

            -- ASCII art
            dashboard.section.header.val = {
                "                                                     ",
                "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
                "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
                "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
                "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
                "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
                "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
                "                                                     ",
            }

            -- Botões com ações úteis
            dashboard.section.buttons.val = {
                dashboard.button("n", "  Novo ficheiro",          "<cmd>ene <BAR> startinsert<CR>"),
                dashboard.button("f", "  Procurar ficheiro",      "<cmd>Telescope find_files<CR>"),
                dashboard.button("r", "  Recentes",               "<cmd>Telescope oldfiles<CR>"),
                dashboard.button("g", "  Grep no projeto",        "<cmd>Telescope live_grep<CR>"),
                dashboard.button("e", "  Harpoon menu",           "<cmd>lua require('harpoon').ui:toggle_quick_menu(require('harpoon'):list())<CR>"),
                dashboard.button("c", "  Configuração Neovim",    "<cmd>cd ~/.config/nvim | e init.lua<CR>"),
                dashboard.button("q", "  Sair",                   "<cmd>qa<CR>"),
            }

            -- Rodapé com versão do Neovim
            local version = vim.version()
            dashboard.section.footer.val = "  Neovim v" .. version.major .. "." .. version.minor .. "." .. version.patch

            -- Highlight
            dashboard.section.header.opts.hl  = "Function"
            dashboard.section.footer.opts.hl  = "Comment"
            dashboard.section.buttons.opts.hl = "Keyword"

            -- Layout (espaçamento entre secções)
            dashboard.config.layout = {
                { type = "padding", val = 4 },
                dashboard.section.header,
                { type = "padding", val = 2 },
                dashboard.section.buttons,
                { type = "padding", val = 2 },
                dashboard.section.footer,
            }

            alpha.setup(dashboard.config)

            vim.keymap.set("n", "<leader>;", "<cmd>Alpha<CR>", { desc = "Dashboard (Alpha)" })

            -- Fecha a tab do alpha quando abres um ficheiro
            vim.api.nvim_create_autocmd("User", {
                pattern = "AlphaReady",
                callback = function()
                    vim.opt_local.foldenable = false
                end,
            })
        end,
    },
}
