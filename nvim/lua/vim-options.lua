vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Indentação
vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")

-- Linha de números
vim.opt.number = true
vim.opt.relativenumber = true

-- Scroll / cursor
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.cursorline = true

-- Clipboard do sistema
vim.opt.clipboard = "unnamedplus"

-- Busca
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false
vim.opt.incsearch = true

-- Splits naturais
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Undo persistente entre sessões
vim.opt.undofile = true
-- Evita escrita de swap/backup desnecessários
vim.opt.swapfile = false
vim.opt.backup = false

-- Melhor experiência visual
vim.opt.signcolumn = "yes"
vim.opt.termguicolors = true
vim.opt.wrap = false
vim.opt.updatetime = 250

-- Guarda ao trocar de buffer
vim.opt.autowrite = true
vim.opt.autowriteall = true

-- Keymaps globais utilitários
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "Save" })
vim.keymap.set("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })
vim.keymap.set("n", "<leader>Q", "<cmd>qa<CR>", { desc = "Quit all" })

-- Desabilitar setas para forçar uso de hjkl
local function block_arrow()
  vim.notify('Use hjkl!', vim.log.levels.WARN)
  return ''
end
for _, mode in ipairs({'n', 'i', 'v', 'c'}) do
  vim.keymap.set(mode, '<Up>', block_arrow, { noremap = true, silent = true })
  vim.keymap.set(mode, '<Down>', block_arrow, { noremap = true, silent = true })
  vim.keymap.set(mode, '<Left>', block_arrow, { noremap = true, silent = true })
  vim.keymap.set(mode, '<Right>', block_arrow, { noremap = true, silent = true })
end

-- Mapear 'jj' para sair do modo insert
vim.keymap.set('i', 'jj', '<Esc>', { noremap = true, silent = true, desc = 'jj para Normal mode' })

-- Navegar entre splits com Ctrl + hjkl
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left split" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right split" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to lower split" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to upper split" })

-- Mover linhas selecionadas no visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Manter cursor centrado ao fazer scroll/search
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Colar sem perder o que está no clipboard
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without losing clipboard" })

-- Copiar para clipboard do sistema explicitamente
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank line to system clipboard" })
