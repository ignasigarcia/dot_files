" Vundle start
set nocompatible               " be iMproved
filetype off                   " required!

set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

Bundle 'gmarik/vundle'

Bundle "tpope/vim-surround"
Bundle "scrooloose/syntastic"
Bundle "scrooloose/nerdtree"
Bundle "jistr/vim-nerdtree-tabs"
Bundle "scrooloose/nerdcommenter"
Bundle "mileszs/ack.vim"
Bundle "flazz/vim-colorschemes"
Bundle "kien/ctrlp.vim"
Bundle "ervandew/supertab"
Bundle "stephpy/vim-php-cs-fixer"
Bundle "spf13/PIV"
Bundle "bling/vim-bufferline"
Bundle "moll/vim-bbye"
Bundle "godlygeek/tabular"
Bundle "MarcWeber/vim-addon-mw-utils"
Bundle "tomtom/tlib_vim"
Bundle "garbas/vim-snipmate"
Bundle "honza/vim-snippets"
Bundle "tsaleh/vim-matchit"

" General settings
syntax on

filetype plugin indent on

set autowrite                           " Writes on buffer exit
set enc=utf-8
set history=100
set number
set ruler
set laststatus=2                        " Always show status
set nrformats=octal,hex,alpha           " Increment octal, hex and alpha values with ctrl-x/ctrl-a
set showcmd                             " Show (partial) commands (or size of selection in Visual mode) in the status line
set showmatch                           " When a bracket is inserted, briefly jump to a matching one
set wildmenu
set wildmode=list:longest,full          " On CMD, first tab shows first result, second tab all
set nofoldenable
set hidden
set backspace=2                         " Enables Backspace
set completeopt-=preview                " Disables preview window after autocomplete

" search
set incsearch
set hlsearch
set ignorecase

" Spaces and tabs
set softtabstop=2
set shiftwidth=2
set tabstop=2
set expandtab

" Indent
set smartindent
set autoindent

" Terminal mode and reporting
set ttym=xterm2
set term=xterm
set mouse=a

" Buffers
au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")|execute("normal `\"")|endif     " Go back to the position the cursor was on the last time this file was edited
au BufRead,BufNewFile *.scss set filetype=scss                                                  " Sass file support

" Bufferline
let g:bufferline_show_bufnr = 0

" Syntastic
let g:syntastic_php_checkers=['php']
let g:syntastic_javascript_checkers = ['jslint']

" PIV
let g:DisableAutoPHPFolding=1

" Ack.vim
let g:ackprg="ack -H --nocolor --nogroup --column"

colorscheme zenburn
set background=light

let mapleader = ","

" Mappings

" save buffer
map <leader>w :w<CR>

" Delete buffer
map <leader>q :Bdelete<CR>

" save changes and clean symfony cache
map <leader>sc :w<CR>:!./symfony cc<CR><CR>

" page down with <Space>
nmap <Space> <PageDown>

" visual shifting (does not exit Visual mode)
vnoremap < <gv
vnoremap > >gv 

" Ack search term
nmap <leader>f :Ack! <cword><CR>

" Run phpunit
map <leader>ut :w<CR>:!phpunit<CR>

" NERDTree toggle
map <Leader>n <plug>NERDTreeTabsToggle<CR>

" Move to next window
map <Tab> <C-W>w

" PHP cs fixer
nnoremap <silent><leader>pcd :call PhpCsFixerFixDirectory()<CR>
nnoremap <silent><leader>pcf :call PhpCsFixerFixFile()<CR>

" Search buffers
map <leader>b :CtrlPBuffer<CR>

" Cycle through buffers
map <C-l> :bn<CR>
map <C-h> :bp<CR>

" Tags
nnoremap <C-]> g<C-]>
vnoremap <C-]> gvg<C-]>

" Tabularize
nmap <Leader>a= :Tabularize /=<CR>
vmap <Leader>a= :Tabularize /=<CR>
nmap <Leader>a: :Tabularize /:\zs<CR>
vmap <Leader>a: :Tabularize /:\zs<CR>

" Clear search highlight
nnoremap <leader>c :noh<CR><CR>

" CtrlP
let g:ctrlp_working_path_mode = 'ra'
nnoremap <silent> <D-t> :CtrlP<CR>
nnoremap <silent> <D-r> :CtrlPMRU<CR>
let g:ctrlp_custom_ignore = {
    \ 'dir':  '\.git$\|\.hg$\|\.svn$',
    \ 'file': '\.exe$\|\.so$\|\.dll$\|\.pyc$' }

let s:ctrlp_fallback = 'ack %s --nocolor -f'

let g:ctrlp_user_command = {
    \ 'types': {
        \ 1: ['.git', 'cd %s && git ls-files . --cached --exclude-standard --others'],
        \ 2: ['.hg', 'hg --cwd %s locate -I .'],
    \ },
    \ 'fallback': s:ctrlp_fallback
\ }

