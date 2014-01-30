" Vundle start
set nocompatible               " be iMproved
filetype off                   " required!

set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" let Vundle manage Vundle
" required! 
Bundle 'gmarik/vundle'

" My Bundles here:
"
" original repos on github
Bundle 'tpope/vim-surround'
Bundle 'scrooloose/syntastic'
Bundle 'joonty/vdebug.git'
Bundle 'scrooloose/nerdtree'
Bundle 'scrooloose/nerdcommenter'
Bundle 'jistr/vim-nerdtree-tabs'
Bundle 'mileszs/ack.vim'
Bundle 'corntrace/bufexplorer'
Bundle 'tsaleh/vim-matchit'
Bundle 'bthemad/php-doc.vim'
Bundle "MarcWeber/vim-addon-mw-utils"
Bundle "tomtom/tlib_vim"
Bundle "garbas/vim-snipmate"
Bundle "honza/vim-snippets"
Bundle "flazz/vim-colorschemes"
Bundle "kien/ctrlp.vim"
Bundle "ervandew/supertab"
Bundle "stephpy/vim-php-cs-fixer"

" Vundle end

" Turn syntax highlighting on
syntax on

filetype plugin indent on
filetype plugin on

" Write contents of the file, if it has been modified, on buffer exit
set autowrite

" Use UTF-8 as the default buffer encoding
set enc=utf-8
 
" Remember up to 100 'colon' commmands and search patterns
set history=100

" Enable incremental search
set incsearch
"
" Highlight results of a search
set hlsearch

" Case insensitive and smart case search
set ignorecase

" Show line number
set number

" Always show status line, even for one window
set laststatus=2

" Enable CTRL-A/CTRL-X to work on octal and hex numbers, as well as characters
set nrformats=octal,hex,alpha

" Show line, column number, and relative position within a file in the status line
set ruler

" Use 2 spaces for tab (ideal for yaml files)
set softtabstop=4
set shiftwidth=4
set tabstop=4
set expandtab

" Show (partial) commands (or size of selection in Visual mode) in the status line
set showcmd

" When a bracket is inserted, briefly jump to a matching one
set showmatch

" Remember things between sessions
"
" '20  - remember marks for 20 previous files
" \"50 - save 50 lines for each register
" :20  - remember 20 items in command-line history 
" %    - remember the buffer list (if vim started without a file arg)
" n    - set name of viminfo file
set viminfo='20,\"50,:20,%,n~/.viminfo

" Use menu to show command-line completion (in 'full' case)
set wildmenu

" Set command-line completion mode:
"   - on first <Tab>, when more than one match, list all matches and complete
"     the longest common  string
"   - on second <Tab>, complete the next full match and show menu
set wildmode=list:longest,full

" Set terminal mode for mouse reporting in iTerm2
set ttym=xterm2
set term=xterm

" Mouse reporting
set mouse=a

" Go back to the position the cursor was on the last time this file was edited
au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")|execute("normal `\"")|endif

" disable folding
set nofoldenable

" colors
colorscheme zenburn
set background=light

"
" MAPPINGS
"
" Set the <Leader> for combo commands
let mapleader = ","

" save changes
map <leader>w :w<CR>

" quit
map <leader>q :q<CR>

" save changes and clean symfony cache
map <leader>sc :w<CR>:!./symfony cc<CR><CR>

" page down with <Space>
nmap <Space> <PageDown>

" visual shifting (does not exit Visual mode)
vnoremap < <gv
vnoremap > >gv 

" Opens tag or list of tags in a new tab
nnoremap <C-]> :tabnew %<CR>g<C-]>
vnoremap <C-]> <Esc>:tabnew %<CR>gvg<C-]>

" Setup ack
let g:ackprg="ack -H --nocolor --nogroup --column"

" Ack search term
nmap <leader>f :Ack! <cword><CR>

" Run phpunit
map <leader>ut :w<CR>:!phpunit<CR>

" NERDTree toggle
map <Leader>n <plug>NERDTreeTabsToggle<CR>

" Cycle through tabs
map <C-l> :tabnext<CR>
map <C-h> :tabprevious<CR>

" PHP documenter
autocmd FileType php inoremap <C-o> <ESC>:call PhpDocSingle()<CR>i
autocmd FileType php nnoremap <C-o> :call PhpDocSingle()<CR>
autocmd FileType php vnoremap <C-o> :call PhpDocRange()<CR> 

" Author for PHP doc
let g:pdv_cfg_Author='Ignacio Garcia Font'

set backspace=2

" Adds Sass support for OS X
au BufRead,BufNewFile *.scss set filetype=scss

" Enable Syntastic check just for PHP errors
let g:syntastic_php_checkers=['php']

" Indent
set smartindent
set autoindent

" PHP cs fixer
nnoremap <silent><leader>pcd :call PhpCsFixerFixDirectory()<CR>
nnoremap <silent><leader>pcf :call PhpCsFixerFixFile()<CR>
