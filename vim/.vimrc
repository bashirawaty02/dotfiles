"──────────────────────────────────────────────
" Basic Settings
"──────────────────────────────────────────────
set nocompatible
syntax on
filetype plugin indent on

set encoding=utf-8
set termguicolors
set number
set relativenumber
set cursorline
set hidden
set showcmd
set showmode
set ruler
set wildmenu
set wildmode=longest:full,full

"──────────────────────────────────────────────
" Search
"──────────────────────────────────────────────
set ignorecase
set smartcase
set incsearch
set hlsearch

" Clear search highlight
nnoremap <silent> <leader>/ :nohlsearch<CR>

"──────────────────────────────────────────────
" Tabs & Indentation
"──────────────────────────────────────────────
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent

"──────────────────────────────────────────────
" UI / Display
"──────────────────────────────────────────────
set scrolloff=5
set sidescrolloff=5
set signcolumn=yes
set splitbelow
set splitright

"──────────────────────────────────────────────
" Clipboard (tmux-friendly)
"──────────────────────────────────────────────
set clipboard=unnamedplus

"──────────────────────────────────────────────
" Status Line (lightweight)
"──────────────────────────────────────────────
set laststatus=2
set statusline=%f\ %y\ %m\ %r\ %=L:%l/%L\ C:%c

"──────────────────────────────────────────────
" File Navigation
"──────────────────────────────────────────────
nnoremap <leader>e :Explore<CR>
nnoremap <leader>t :tabnew<CR>

"──────────────────────────────────────────────
" Better Window Navigation (tmux-like)
"──────────────────────────────────────────────
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

"──────────────────────────────────────────────
" Faster Escape
"──────────────────────────────────────────────
inoremap jk <Esc>
inoremap jj <Esc>

"──────────────────────────────────────────────
" Persistent Undo
"──────────────────────────────────────────────
set undofile
set undodir=~/.vim/undo

"──────────────────────────────────────────────
" Folding (indent-based)
"──────────────────────────────────────────────
set foldmethod=indent
set foldlevel=99

"──────────────────────────────────────────────
" Python / Ansible / YAML
"──────────────────────────────────────────────
autocmd FileType python setlocal tabstop=4 shiftwidth=4 expandtab
autocmd FileType yaml setlocal tabstop=2 shiftwidth=2 expandtab
autocmd FileType yml setlocal tabstop=2 shiftwidth=2 expandtab

"──────────────────────────────────────────────
" Highlight trailing whitespace
"──────────────────────────────────────────────
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/

"──────────────────────────────────────────────
" Save & Quit Shortcuts
"──────────────────────────────────────────────
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>x :x<CR>

"──────────────────────────────────────────────
" Leader Key
"──────────────────────────────────────────────
let mapleader=" "

"──────────────────────────────────────────────
" Tmux Integration
"──────────────────────────────────────────────
if exists('$TMUX')
    set ttymouse=xterm2
endif

"──────────────────────────────────────────────
" Colorscheme (safe fallback)
"──────────────────────────────────────────────
colorscheme desert
