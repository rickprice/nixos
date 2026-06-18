-- ── Options ───────────────────────────────────────────────────────────────
vim.g.loaded            = 1
vim.g.loaded_netrwPlugin = 1
vim.g.autoformat        = false
vim.g.vimwiki_global_ext = 0
vim.g.history           = 10000
vim.g.markdown_fenced_languages = { "html", "javascript", "typescript", "css", "scss", "lua", "vim" }

local opt = vim.opt
opt.backspace      = { "indent", "eol", "start" }
opt.clipboard      = "unnamed"
opt.colorcolumn    = "100"
opt.completeopt    = "menu,menuone,noselect"
opt.cursorcolumn   = false
opt.cursorline     = false
opt.encoding       = "utf-8"
opt.expandtab      = true
opt.foldlevel      = 99
opt.foldenable     = false
opt.foldmethod     = "expr"
opt.foldexpr       = "v:lua.vim.treesitter.foldexpr()"
opt.formatoptions  = "l"
opt.guicursor      = "n-v-c-sm:block-blinkwait50-blinkon50-blinkoff50,i-ci-ve:ver25-Cursor-blinkon100-blinkoff100,r-cr-o:hor20"
opt.hidden         = true
opt.hlsearch       = true
opt.ignorecase     = true
opt.inccommand     = "split"
opt.incsearch      = true
opt.joinspaces     = false
opt.linebreak      = true
opt.list           = true
opt.listchars      = "eol:¬,tab:>·,trail:~,extends:>,precedes:<,space:␣"
opt.mouse          = "a"
opt.number         = false
opt.relativenumber = false
opt.scrolloff      = 4
opt.shiftround     = true
opt.shiftwidth     = 4
opt.showmode       = false
opt.sidescrolloff  = 8
opt.signcolumn     = "auto:9"
opt.smartcase      = true
opt.smartindent    = true
opt.spelllang      = { "en_gb" }
opt.splitbelow     = true
opt.splitright     = true
opt.tabstop        = 4
opt.termguicolors  = true
opt.undodir        = vim.fn.stdpath("config") .. "/undo"
opt.undofile       = true
opt.undolevels     = 10000
opt.wrap           = true
opt.wrapscan       = false
vim.o.whichwrap    = vim.o.whichwrap .. "<,>"

-- ── Autocmds ──────────────────────────────────────────────────────────────
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.highlight.on_yank({ on_visual = true }) end,
})

-- ── Filetype detection (Next.js) ──────────────────────────────────────────
vim.filetype.add({
  extension = { mdx = "mdx" },
  filename  = {
    [".eslintrc.json"] = "json",
    ["next.config.js"] = "javascript",
    ["next.config.ts"] = "typescript",
  },
})

-- ── Auto-setup helper ─────────────────────────────────────────────────────
-- For each { "module.name", opts = {} } entry, calls require(mod).setup(opts).
-- Skips gracefully if the plugin is missing or has no setup().
local function setup_all(specs)
  for _, spec in ipairs(specs) do
    local mod  = spec[1]
    local opts = spec.opts or {}
    local ok, plugin = pcall(require, mod)
    if ok and type(plugin) == "table" and type(plugin.setup) == "function" then
      local ok2, err = pcall(plugin.setup, opts)
      if not ok2 then
        vim.notify("[nvim] " .. mod .. ": " .. tostring(err), vim.log.levels.WARN)
      end
    elseif not ok then
      vim.notify("[nvim] could not load: " .. mod, vim.log.levels.WARN)
    end
  end
end

-- ── Plugins ───────────────────────────────────────────────────────────────
-- Plugins that only need setup({}) with no custom options.
setup_all({
  { "marks" },
  { "nvim-autopairs" },
  { "symbols-outline" },
  { "mason" },
  { "neogit" },
  { "telescope" },
  { "todo-comments" },
  { "zen-mode" },
})

-- ── Colorscheme ───────────────────────────────────────────────────────────
require("nightfox").setup({ options = { transparent = true } })
vim.cmd.colorscheme("nightfox")

-- ── Treesitter ────────────────────────────────────────────────────────────
-- nvim-treesitter 0.10+ removed the configs module; highlight/indent are
-- now built-in neovim features. Parsers are provided by Nix.
vim.api.nvim_create_autocmd("FileType", {
  callback = function() pcall(vim.treesitter.start) end,
})

-- ── Completion ────────────────────────────────────────────────────────────
require("blink.cmp").setup({
  keymap     = { preset = "default" },
  appearance = { nerd_font_variant = "mono" },
  completion = { documentation = { auto_show = false } },
  sources    = {
    default = { "lsp", "path", "snippets", "buffer" },
    providers = {
      lsp      = { name = "LSP",     fallbacks = { "buffer" } },
      path     = { name = "Path",    score_offset = -3 },
      snippets = { name = "Snippet", score_offset = -1 },
      buffer   = { name = "Text",    fallbacks = {} },
    },
  },
  fuzzy = { implementation = "prefer_rust_with_warning" },
})

-- ── Formatting ────────────────────────────────────────────────────────────
require("conform").setup({
  formatters_by_ft = {
    javascript      = { "prettier" },
    javascriptreact = { "prettier" },
    typescript      = { "prettier" },
    typescriptreact = { "prettier" },
    json            = { "prettier" },
    html            = { "prettier" },
    css             = { "prettier" },
    scss            = { "prettier" },
    markdown        = { "prettier" },
    yaml            = { "prettier" },
  },
  format_on_save = { timeout_ms = 500, lsp_fallback = true },
})

-- ── Git ───────────────────────────────────────────────────────────────────
require("gitsigns").setup({
  signs = {
    add          = { text = "▎" },
    change       = { text = "▎" },
    delete       = { text = "" },
    topdelete    = { text = "" },
    changedelete = { text = "▎" },
    untracked    = { text = "▎" },
  },
  on_attach = function(buf)
    local gs = package.loaded.gitsigns
    local function map(mode, l, r, desc)
      vim.keymap.set(mode, l, r, { buffer = buf, desc = desc })
    end
    map("n",       "]h",          gs.next_hunk,                                   "Next Hunk")
    map("n",       "[h",          gs.prev_hunk,                                   "Prev Hunk")
    map({"n","v"}, "<leader>ghs", ":Gitsigns stage_hunk<CR>",                     "Stage Hunk")
    map({"n","v"}, "<leader>ghr", ":Gitsigns reset_hunk<CR>",                     "Reset Hunk")
    map("n",       "<leader>ghS", gs.stage_buffer,                                "Stage Buffer")
    map("n",       "<leader>ghu", gs.undo_stage_hunk,                             "Undo Stage Hunk")
    map("n",       "<leader>ghR", gs.reset_buffer,                                "Reset Buffer")
    map("n",       "<leader>ghp", gs.preview_hunk,                                "Preview Hunk")
    map("n",       "<leader>ghb", function() gs.blame_line({ full = true }) end,  "Blame Line")
    map("n",       "<leader>ghd", gs.diffthis,                                    "Diff This")
    map("n",       "<leader>ghD", function() gs.diffthis("~") end,                "Diff This ~")
    map({"o","x"}, "ih",          ":<C-U>Gitsigns select_hunk<CR>",               "Select Hunk")
  end,
})

-- ── Hop ───────────────────────────────────────────────────────────────────
vim.cmd("hi HopNextKey  guifg=#ff9900")
vim.cmd("hi HopNextKey1 guifg=#ff9900")
vim.cmd("hi HopNextKey2 guifg=#ff9900")
require("hop").setup()

-- ── Noice ─────────────────────────────────────────────────────────────────
require("noice").setup({
  history = {
    view = "popup",
    opts = { enter = true, format = "details" },
    filter = {
      any = {
        { event = "notify" },
        { error = true },
        { warning = true },
        { event = "msg_show", kind = { "" } },
        { event = "lsp", kind = "message" },
      },
    },
  },
})

-- ── Rainbow delimiters ────────────────────────────────────────────────────
local rainbow = require("rainbow-delimiters")
vim.g.rainbow_delimiters = {
  strategy = {
    [""] = rainbow.strategy["global"],
    vim  = rainbow.strategy["local"],
  },
  query = {
    [""] = "rainbow-delimiters",
    lua  = "rainbow-blocks",
  },
  highlight = {
    "RainbowDelimiterRed",    "RainbowDelimiterYellow", "RainbowDelimiterBlue",
    "RainbowDelimiterOrange", "RainbowDelimiterGreen",  "RainbowDelimiterViolet",
    "RainbowDelimiterCyan",
  },
}

-- ── Trouble ───────────────────────────────────────────────────────────────
require("trouble").setup({ use_diagnostic_signs = true })

-- ── Which-key ─────────────────────────────────────────────────────────────
vim.o.timeout    = true
vim.o.timeoutlen = 500
require("which-key").setup()

-- ── Renamer ───────────────────────────────────────────────────────────────
require("renamer").setup()

-- ── Toggleterm ────────────────────────────────────────────────────────────
require("toggleterm").setup()

-- ── DAP UI ────────────────────────────────────────────────────────────────
require("dapui").setup()

-- ── LSP ───────────────────────────────────────────────────────────────────
-- Attach common keymaps whenever an LSP connects to a buffer.
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local function map(mode, key, fn, desc)
      vim.keymap.set(mode, key, fn, { buffer = ev.buf, desc = desc })
    end
    map("n", "gd",         vim.lsp.buf.definition,     "Go to definition")
    map("n", "K",          vim.lsp.buf.hover,          "Hover")
    map("n", "<leader>ca", vim.lsp.buf.code_action,    "Code action")
    map("n", "<leader>rn", vim.lsp.buf.rename,         "Rename")
    map("n", "gr",         vim.lsp.buf.references,     "References")
    map("n", "gi",         vim.lsp.buf.implementation, "Implementation")
  end,
})

local lspconfig = require("lspconfig")

lspconfig.tailwindcss.setup({
  filetypes = {
    "css", "scss", "sass", "html",
    "javascript", "javascriptreact", "typescript", "typescriptreact",
  },
  root_dir = lspconfig.util.root_pattern(
    "tailwind.config.js", "tailwind.config.ts",
    "tailwind.config.cjs", "tailwind.config.mjs"
  ),
})

lspconfig.cssls.setup({
  settings = {
    css  = { validate = true, lint = { unknownAtRules = "ignore" } },
    scss = { validate = true, lint = { unknownAtRules = "ignore" } },
  },
})

lspconfig.html.setup({
  filetypes = { "html", "javascriptreact", "typescriptreact" },
})

lspconfig.jsonls.setup({
  settings = {
    json = {
      schemas = {
        { fileMatch = { "package.json" },                      url = "https://json.schemastore.org/package.json" },
        { fileMatch = { "tsconfig.json", "tsconfig.*.json" }, url = "https://json.schemastore.org/tsconfig.json" },
        { fileMatch = { ".eslintrc", ".eslintrc.json" },       url = "https://json.schemastore.org/eslintrc.json" },
        { fileMatch = { "next.config.js" },                    url = "https://json.schemastore.org/next.json" },
      },
    },
  },
})

lspconfig.eslint.setup({
  settings = { workingDirectory = { mode = "auto" } },
})

require("typescript-tools").setup({
  settings = {
    tsserver_file_preferences = {
      includeInlayParameterNameHints                        = "all",
      includeInlayParameterNameHintsWhenArgumentMatchesName = false,
      includeInlayFunctionParameterTypeHints                = true,
      includeInlayVariableTypeHints                         = true,
      includeInlayPropertyDeclarationTypeHints              = true,
      includeInlayFunctionLikeReturnTypeHints               = true,
      includeInlayEnumMemberValueHints                      = true,
    },
  },
})

-- ── Obsidian ──────────────────────────────────────────────────────────────
require("obsidian").setup({
  workspaces = {
    { name = "personal", path = "~/Documents/Personal/Dropbox/FrederickDocuments/MarkDownDocuments.personal" },
    { name = "work",     path = "~/Documents/Personal/Dropbox/FrederickDocuments/MarkDownDocuments.work" },
  },
  daily_notes  = { folder = "journal/daily",  date_format = "%Y-%m-%d", alias_format = "%B %-d, %Y",         template = "daily-note.md" },
  weekly_notes = { folder = "journal/weekly", date_format = "%Y-W%V",   alias_format = "Week of %B %-d, %Y", template = "weekly-note.md" },
  completion   = { nvim_cmp = false, min_chars = 2 },
  templates    = { subdir = "templates", date_format = "%Y-%m-%d", time_format = "%H:%M" },
  note_id_func = function(title)
    local suffix = title and title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
      or (function()
           local s = ""
           for _ = 1, 4 do s = s .. string.char(math.random(65, 90)) end
           return s
         end)()
    return tostring(os.time()) .. "-" .. suffix
  end,
  mappings = {
    ["gf"]         = { action = function() return require("obsidian").util.gf_passthrough() end, opts = { noremap = false, expr = true, buffer = true } },
    ["<leader>ch"] = { action = function() return require("obsidian").util.toggle_checkbox() end, opts = { buffer = true } },
    ["<cr>"]       = { action = function() return require("obsidian").util.smart_action() end,    opts = { buffer = true, expr = true } },
  },
})

-- ── Keymaps ───────────────────────────────────────────────────────────────
local map = vim.keymap.set

-- Line numbers / whitespace
map("n", "<F2>",        ":let [&nu, &rnu] = [!&rnu, &nu+&rnu==1]<cr>", { desc = "Toggle line numbers" })
map("n", "<F3>",        ":set list!<CR>",                               { desc = "Toggle show whitespace" })
map("n", "<leader>dtw", ":%s/\\s\\+$//e<cr>",                          { desc = "Delete trailing whitespace" })

-- Hop
map({"n","v"}, "<leader>h", "<cmd>lua require'hop'.hint_words()<cr>", { desc = "Hop Anywhere" })

-- Trouble
map("n", "<leader>xx", ":Trouble diagnostics toggle<CR>",               { desc = "Toggle diagnostics" })
map("n", "<leader>xd", ":Trouble diagnostics toggle filter.buf=0<CR>", { desc = "Toggle document diagnostics" })
map("n", "<leader>xq", ":Trouble quickfix toggle<CR>",                  { desc = "Toggle quickfix list" })
map("n", "<leader>xl", ":Trouble loclist toggle<CR>",                   { desc = "Toggle location list" })
map("n", "<leader>xt", ":Trouble todo toggle<CR>",                      { desc = "Toggle todos list" })
map("n", "<leader>xh", ":lua vim.diagnostic.hide()<CR>",               { desc = "Hide diagnostics" })
map("n", "<leader>xs", ":lua vim.diagnostic.show()<CR>",               { desc = "Show diagnostics" })

-- Toggleterm
map("n", "<leader>T", "<cmd>ToggleTerm<cr>", { desc = "ToggleTerm" })

-- Renamer
map({"n","v"}, "<leader>cn", '<cmd>lua require("renamer").rename()<cr>', { desc = "Rename" })

-- Symbols outline
map("n", "<leader>cs", "<cmd>SymbolsOutline<cr>", { desc = "Symbols Outline" })

-- Obsidian
map("n", "<leader>on",  "<cmd>ObsidianNew<cr>",         { desc = "New note" })
map("n", "<leader>oo",  "<cmd>ObsidianOpen<cr>",        { desc = "Open in Obsidian" })
map("n", "<leader>ob",  "<cmd>ObsidianBacklinks<cr>",   { desc = "Backlinks" })
map("n", "<leader>otp", "<cmd>ObsidianTemplate<cr>",    { desc = "Insert template" })
map("n", "<leader>op",  "<cmd>ObsidianPasteImg<cr>",    { desc = "Paste image" })
map("n", "<leader>or",  "<cmd>ObsidianRename<cr>",      { desc = "Rename note" })
map("n", "<leader>od",  "<cmd>ObsidianDailies<cr>",     { desc = "Daily notes" })
map("n", "<leader>ot",  "<cmd>ObsidianToday<cr>",       { desc = "Today's note" })
map("n", "<leader>oy",  "<cmd>ObsidianYesterday<cr>",   { desc = "Yesterday's note" })
map("n", "<leader>otm", "<cmd>ObsidianTomorrow<cr>",    { desc = "Tomorrow's note" })
map("n", "<leader>ow",  "<cmd>ObsidianWeek<cr>",        { desc = "This week's note" })
map("n", "<leader>of",  "<cmd>ObsidianQuickSwitch<cr>", { desc = "Quick switch notes" })
map("n", "<leader>os",  "<cmd>ObsidianSearch<cr>",      { desc = "Search notes" })
map("n", "<leader>ol",  "<cmd>ObsidianLinks<cr>",       { desc = "Collect links" })
map("n", "<leader>otg", "<cmd>ObsidianTags<cr>",        { desc = "Show tags" })

-- Custom: run external command on visual selection
map("v", "<leader>H", function()
  local arg = table.concat(vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos(".")), " ")
  vim.cmd("vert new | setlocal buftype=nofile bufhidden=wipe nobuflisted")
  -- local cmd = "Xinv-patch download --force --filename /dev/stdout --patch-id " .. arg
  -- vim.cmd("0r !" .. cmd)
end, { desc = "Run external cmd on selection → vert split", silent = true })
