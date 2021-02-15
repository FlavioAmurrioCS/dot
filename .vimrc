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
"My color preferences for lecturing
"highlight Search ctermbg=DarkMagenta ctermfg=cyan
"highlight Comment ctermfg=LightBlue



set hlsearch
set splitright
set splitbelow
set omnifunc=syntaxcomplete#Complete
autocmd BufWritePre * :%s/\s\+$//e

""""" Plugins
call plug#begin()
  Plug 'vim-scripts/CycleColor'
  Plug 'morhetz/gruvbox'
call plug#end()

try
  colorscheme gruvbox
catch
    colorscheme desert
endtry


