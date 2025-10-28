return {
  {
    "kwsp/halcyon-neovim",
    priority = 1000,
    lazy = false,
    config = function()
      vim.cmd.colorscheme("halcyon")
    end,
  },
}
