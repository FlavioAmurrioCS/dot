set nocompatible

syntax enable
filetype plugin on

colorscheme desert

set path+=**

set wildmenu

command! MakeTags !ctags -R .

set ignorecase
set smartcase
set incsearch
set tabstop=2
set shiftwidth=2
set expandtab
au FileType python setlocal formatprg=autopep8\ -
set mouse=a
set number relativenumber
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave,WinEnter * if &nu && mode() != "i" | set rnu   | endif
  autocmd BufLeave,FocusLost,InsertEnter,WinLeave   * if &nu                  | set nornu | endif
augroup END

"From CS531
set cursorline
set colorcolumn=100
set showmatch
set autoindent
set smartindent
set cindent
set ruler
set encoding=utf-8
set pastetoggle=<f5>
"Treat any .s files as assembly
autocmd BufNewFile,BufRead *.s set ft=masm
"Don't turn tabs to spaces for makefiles
autocmd FileType make setlocal noexpandtab
autocmd FileType python nnoremap ,format :gggqG
"My color preferences for lecturing
"highlight Search ctermbg=DarkMagenta ctermfg=cyan
"highlight Comment ctermfg=LightBlue

" File Browsing:
let g:netrw_banner=0        " disable annoying banner
let g:netrw_browse_split=4  " open in prior window
let g:netrw_altv=1          " open splits to the right
let g:netrw_liststyle=3     " tree view
let g:netrw_list_hide=netrw_gitignore#Hide()
let g:netrw_list_hide.=',\(^\|\s\s\)\zs\.\S\+'
set showcmd

set hlsearch
set splitright
set splitbelow
set omnifunc=syntaxcomplete#Complete
autocmd BufWritePre * :%s/\s\+$//e

""""" Plugins
call plug#begin()
  Plug 'vim-scripts/CycleColor'
  Plug 'morhetz/gruvbox'
  Plug 'lifepillar/vim-mucomplete'
"  Plug 'davidhalter/jedi-vim'
call plug#end()

try
  colorscheme gruvbox
catch
    colorscheme desert
endtry

set backspace=indent,eol,start

set completeopt+=menuone
set shortmess+=c   " Shut off completion messages
set belloff+=ctrlg " If Vim beeps during completion
let g:mucomplete#enable_auto_at_startup = 1
let g:mucomplete#completion_delay = 1

"set completeopt-=preview
set completeopt+=longest,menuone,noselect
"let g:jedi#popup_on_dot = 0  " It may be 1 as well
let g:mucomplete#enable_auto_at_startup = 1
