return { -- Mason: manages LSP servers, formatters, linters, DAP adapters
{
    "mason-org/mason.nvim",
    opts = {
        ui = {
            icons = {
                package_installed = "✓",
                package_pending = "➜",
                package_uninstalled = "✗"
            }
        }
    },
    config = function()
        require("mason").setup()
    end
}, -- Ensures formatters and linters are installed via Mason
{
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    config = function()
        require("mason-tool-installer").setup({
            ensure_installed = { -- Formatters
            "stylua", -- Lua
            "clang-format", -- C/C++
            "prettier", -- TS/JS/HTML/CSS/JSON/Vue/Angular
            "goimports", -- Go (also runs gofmt)
            -- Linters
            "cpplint", -- C/C++
            "eslint_d", -- TypeScript/JavaScript
            "golangci-lint" -- Go
            -- luacheck installed via apt (sudo apt install lua-check)
            }
        })
    end
}, -- Bridges Mason with nvim-lspconfig
{
    "mason-org/mason-lspconfig.nvim",
    config = function()
        require("mason-lspconfig").setup({
            ensure_installed = {"lua_ls", -- Lua (neovim config)
            "clangd", -- C/C++
            "rust_analyzer", -- Rust
            "ts_ls", -- TypeScript/JavaScript (Workers, React, Vue, Angular)
            "eslint", -- ESLint as LSP
            "gopls", -- Go
            "html", -- HTML
            "cssls", -- CSS
            "tailwindcss", -- Tailwind CSS
            "jsonls", -- JSON
            "yamlls", -- YAML
            "angularls", -- Angular
            "bashls", -- Bash/Shell
            "dockerls" -- Dockerfile
            -- Note: dartls ships with Flutter SDK, not via Mason
            }
        })
    end
}, -- LSP server configuration
{
    "neovim/nvim-lspconfig",
    config = function()

        -- C/C++
        vim.lsp.config('clangd', {})
        vim.lsp.enable('clangd')

        -- Rust
        vim.lsp.config('rust_analyzer', {})
        vim.lsp.enable('rust_analyzer')

        -- TypeScript/JavaScript (Cloudflare Workers, React, Vue, Angular)
        vim.lsp.config('ts_ls', {})
        vim.lsp.enable('ts_ls')

        vim.lsp.config('eslint', {})
        vim.lsp.enable('eslint')

        -- Go
        vim.lsp.config('gopls', {})
        vim.lsp.enable('gopls')

        -- HTML / CSS / Tailwind
        vim.lsp.config('html', {})
        vim.lsp.enable('html')

        vim.lsp.config('cssls', {})
        vim.lsp.enable('cssls')

        vim.lsp.config('tailwindcss', {})
        vim.lsp.enable('tailwindcss')

        -- JSON / YAML
        vim.lsp.config('jsonls', {})
        vim.lsp.enable('jsonls')

        vim.lsp.config('yamlls', {})
        vim.lsp.enable('yamlls')

        -- Angular
        vim.lsp.config('angularls', {})
        vim.lsp.enable('angularls')

        -- Shell / Docker
        vim.lsp.config('bashls', {})
        vim.lsp.enable('bashls')

        vim.lsp.config('dockerls', {})
        vim.lsp.enable('dockerls')

        -- Lua (with neovim globals awareness)
        vim.lsp.config('lua_ls', {
            settings = {
                Lua = {
                    diagnostics = {
                        globals = {'vim'}
                    },
                    workspace = {
                        library = vim.api.nvim_get_runtime_file("", true),
                       
                        checkThirdParty = false
                    },
                    telemetry = {
                        enable = false
                    }
                }
            }
        })
        vim.lsp.enable('lua_ls')

        -- Dart/Flutter: dartls is bundled with the Flutter SDK
        -- Requires flutter/dart to be in PATH
        vim.lsp.config('dartls', {})
        vim.lsp.enable('dartls')

        -- Keymaps
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, {
            desc = "LSP Hover"
        })
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {
            desc = "Go to Definition"
        })
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, {
            desc = "Go to References"
        })
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, {
            desc = "Go to Implementation"
        })
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, {
            desc = "Rename Symbol"
        })
        vim.keymap.set({'n', 'v'}, '<leader>ca', vim.lsp.buf.code_action, {
            desc = "Code Action"
        })
        vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, {
            desc = "Show Diagnostic"
        })
        vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, {
            desc = "Previous Diagnostic"
        })
        vim.keymap.set('n', ']d', vim.diagnostic.goto_next, {
            desc = "Next Diagnostic"
        })
    end
}, -- conform.nvim: auto-formatting on save
{
    "stevearc/conform.nvim",
    event = {"BufWritePre"},
    cmd = {"ConformInfo"},
    config = function()
        require("conform").setup({
            formatters_by_ft = {
                lua = {"stylua"},
                c = {"clang_format"},
                cpp = {"clang_format"},
                rust = {"rustfmt"}, -- rustfmt comes with rustup
                go = {"goimports"}, -- goimports runs gofmt internally
                typescript = {"prettier"},
                javascript = {"prettier"},
                typescriptreact = {"prettier"},
                javascriptreact = {"prettier"},
                html = {"prettier"},
                css = {"prettier"},
                scss = {"prettier"},
                json = {"prettier"},
                yaml = {"prettier"},
                vue = {"prettier"},
                dart = {"dart_format"} -- dart format from Flutter SDK
            },
            format_on_save = {
                timeout_ms = 500,
                lsp_fallback = true
            }
        })
    end
}, -- nvim-lint: linting on save/open
{
    "mfussenegger/nvim-lint",
    event = {"BufReadPost", "BufWritePost"},
    config = function()
        require("lint").linters_by_ft = {
            -- c/cpp: clangd LSP already handles diagnostics + code actions
            -- eslint: eslint LSP handles TS/JS diagnostics + code actions
            go = {"golangcilint"}, -- gopls doesn't include golangci-lint rules
            lua = {"luacheck"} -- lua_ls misses some style rules
        }
        vim.api.nvim_create_autocmd({"BufWritePost", "BufReadPost"}, {
            callback = function()
                require("lint").try_lint()
            end
        })
    end
}}
