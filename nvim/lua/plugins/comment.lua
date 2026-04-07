return {
    {
        "numToStr/Comment.nvim",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("Comment").setup()
            -- gcc → comentar linha
            -- gc{motion} → comentar com motion (ex: gcip para parágrafo)
            -- gbc → comentar bloco
        end,
    },
}
