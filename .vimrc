" Turn syntax highlighting on
syntax on

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

" Indent
set autoindent
set smartindent

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
" save changes and clean cache
map <leader>sc :w<CR>:!./symfony cc<CR><CR>

" switch to upper/lower window quickly
map <C-J> <C-W>j
map <C-K> <C-W>k
" use CTRL-F for omni completion
imap <C-F> 
" map CTRL-L to piece-wise copying of the line above the current one
imap <C-L> @@@<ESC>hhkywjl?@@@<CR>P/@@@<CR>3s
" map ,f to display all lines with keyword under cursor and ask which one to
" jump to
nmap <leader>f [I:let nr = input("Which one: ")<Bar>exe "normal " . nr ."[\t"<CR>
" page down with <Space>
nmap <Space> <PageDown>
" open filename under cursor in a new window (use current file's working
" directory) 
nmap gf :new %:p:h/<cfile><CR>
" map <Alt-p> and <Alt-P> to paste below/above and reformat
nnoremap <Esc>P  P'[v']=
nnoremap <Esc>p  p'[v']=
" visual shifting (does not exit Visual mode)
vnoremap < <gv
vnoremap > >gv 

" Open tags in a new tab
map <C-\> :tab split<CR>:exec("tag ".expand("<cword>"))<CR>

" Setup ack
let g:ackprg="ack -H --nocolor --nogroup --column"

" Ack search term
nmap <leader>z :Ack <cword><CR>

" NERDTree toggle
map <leader>n :NERDTreeToggle<CR>

" Go to latest opened buffer
nmap ff :b#<CR>

" Show and go to latest buffer?
nnoremap <Tab><Tab> :buffers<CR>:buffer<Space>

" Cycle through buffers
map <C-l> :bn<CR>
map <C-h> :bp<CR>

" PHP documenter script bound to Control-P
autocmd FileType php inoremap <C-o> <ESC>:call PhpDocSingle()<CR>i
autocmd FileType php nnoremap <C-o> :call PhpDocSingle()<CR>
autocmd FileType php vnoremap <C-o> :call PhpDocRange()<CR> 

" CtrlP plugin
set runtimepath^=~/.vim/bundle/ctrlp.vim
" Tells CrtlP to always start looking from the initial path
let g:ctrlp_working_path_mode = ''

"Tagbar
nmap <leader>rt :TagbarToggle<CR>

set paste
