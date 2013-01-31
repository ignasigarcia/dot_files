"Pathogen
execute pathogen#infect()

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
set softtabstop=2
set shiftwidth=2
set tabstop=2
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
"
" MAPPINGS
"
" Set the <Leader> for combo commands
let mapleader = ","

" save changes
map <leader>w :w<CR>

" save changes and clean symfony cache
map <leader>sc :w<CR>:!./symfony cc<CR><CR>

" map ,f to display all lines with keyword under cursor and ask which one to jump to
nmap <leader>f [I:let nr = input("Which one: ")<Bar>exe "normal " . nr ."[\t"<CR>

" page down with <Space>
nmap <Space> <PageDown>

" visual shifting (does not exit Visual mode)
vnoremap < <gv
vnoremap > >gv 

" Open tags in a new tab
map <leader>o :tab split<CR>:exec("tag ".expand("<cword>"))<CR>

" Setup ack
let g:ackprg="ack -H --nocolor --nogroup --column"

" Ack search term
nmap <leader>a :Ack <cword><CR>

" NERDTree toggle
map <leader>n :NERDTreeToggle<CR>

" Cycle through buffers
map <C-l> :tabnext<CR>
map <C-h> :tabprevious<CR>

" PHP documenter script bound to Control-P
autocmd FileType php inoremap <C-o> <ESC>:call PhpDocSingle()<CR>i
autocmd FileType php nnoremap <C-o> :call PhpDocSingle()<CR>
autocmd FileType php vnoremap <C-o> :call PhpDocRange()<CR> 

set backspace=2

" Indent
set smartindent
set autoindent

" Adds Sass support for OS X
au BufRead,BufNewFile *.scss set filetype=scss
