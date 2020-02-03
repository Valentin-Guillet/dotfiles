" +=====================+
" |   GENERAL OPTIONS   |
" +=====================+

" Define leader
let mapleader = ","

" Use Vim settings, rather than Vi
set nocompatible

" Allow backspacing over everything in insert mode
set backspace=indent,eol,start

" Don't display message when running vim without file
set shortmess+=I

" Replace patterns act on every occurence in line by default
" (and use g-flag to use default behavior)
set gdefault

" Better autocompletion in command mode
set wildmenu

set hidden

set history=50	    " keep 50 lines of command line history
set ruler           " show the cursor position all the time
set showcmd	        " display incomplete commands
set incsearch       " do incremental searching
set ignorecase
set smartcase       " case-sensitive search only when at least one capital letter

set path+=**        " set recursive path to use :find

set splitright      " new splits on the right...
set splitbelow      " ... and below

set expandtab
set smarttab

set shiftwidth=4
set tabstop=4
set shiftround

set autoindent
set smartindent

set linebreak       " break line between words during wrap
set lazyredraw      " don't update screen during macros

set timeout ttimeoutlen=50

if has('mouse')
    set mouse=a
endif

" Prevent that the langmap option applies to characters that result from a mapping
if has('langmap') && exists('+langnoremap')
    set langnoremap
endif

if has("autocmd")
    " Enable file type detection.
    " Also load indent files, to automatically do language-dependent indenting.
    filetype plugin indent on

    " Put these in an autocmd group, so that we can delete them easily.
    augroup vimrcEx
        au!

        " For all text files set 'textwidth' to 78 characters.
        autocmd FileType text setlocal textwidth=78

        " When editing a file, always jump to the last known cursor position.
        autocmd BufReadPost *
                    \ if line("'\"") >= 1 && line("'\"") <= line("$") |
                    \   exe "normal! g`\"" |
                    \ endif
    augroup END
endif

" Switch syntax highlighting on, when the terminal has colors
if &t_Co > 2 || has("gui_running")
    syntax on
endif


set backup
set undofile

if !isdirectory($HOME . "/.config/vim/backup")
    call mkdir($HOME . "/.config/vim/backup", "p")
endif
if !isdirectory($HOME . "/.config/vim/swap")
    call mkdir($HOME . "/.config/vim/swap", "p")
endif
if !isdirectory($HOME . "/.config/vim/undo")
    call mkdir($HOME . "/.config/vim/undo", "p")
endif

set backupdir=~/.config/vim/backup//,/tmp//
set directory=~/.config/vim/swap//,/tmp//
set undodir=~/.config/vim/undo//,/tmp//


set dictionary+=/usr/share/dict/words


" +=========================+
" |   ADDITIONAL PACKAGES   |
" +=========================+

set runtimepath^=~/.config/vim/

try
    packadd matchit
catch /.*/
endtry

" Auto-pairs
let g:AutoPairsShortcutToggle = ''
let g:AutoPairsShortcutJump = '<M-f>'
let g:AutoPairsMapCh = 0

" Vim/Tmux navigator
let g:tmux_navigator_disable_when_zoomed = 1

" Zoom pane
let g:zoom#statustext = '[Z]'


" +===================+
" |   USER MAPPINGS   |
" +===================+

" Edit and reload vim config
nnoremap <leader>e :call OpenInSplitIfNotEmpty($MYVIMRC)<CR>
nnoremap <leader>E :tabnew $MYVIMRC<CR>
nnoremap <leader>r :source $MYVIMRC<CR>:echo "Config reloaded !"<CR>

" Write file with <leader>w
nnoremap <leader>w :update <CR>

" Split
nnoremap <leader>\ :vsplit<CR>
nnoremap <leader>- :split<CR>
nnoremap <leader>= <C-w>=
nnoremap <leader>q :q<CR>

" Move splits around
nnoremap <leader>H <C-w>H
nnoremap <leader>J <C-w>J
nnoremap <leader>K <C-w>K
nnoremap <leader>L <C-w>L

" Tabs
nnoremap <leader>t :tab split<CR>
nnoremap <leader>n :tabnext<CR>
nnoremap <leader>p :tabprev<CR>

nnoremap <leader>N :tabm <C-R>=(tabpagenr()+1)%(tabpagenr('$')+1)<CR><CR>
nnoremap <leader>P :tabm <C-R>=(tabpagenr()+tabpagenr('$')-1)%(tabpagenr('$')+1)<CR><CR>

nnoremap <leader>< <C-W>R
nnoremap <leader>> <C-W>r

" Send split to new tab
nnoremap <leader>! <C-W>T

" Scroll with C-[j|k]
nnoremap <C-j> <C-e>
vnoremap <C-j> <C-e>
inoremap <C-j> <C-x><C-e>
nnoremap <C-k> <C-y>
vnoremap <C-k> <C-y>
inoremap <C-k> <C-x><C-y>

" Exit insert mode with kj
inoremap kj <Esc>l
inoremap Kj <Esc>l
inoremap kJ <Esc>l
inoremap KJ <Esc>l

" Move line
nnoremap <silent> - :m .+1<CR>==
nnoremap <silent> _ :m .-2<CR>==
vnoremap <silent> - :m '>+1<CR>gv=gv
vnoremap <silent> _ :m '<-2<CR>gv=gv

" Add a new line
nnoremap <C-h> o<Esc>

" Operator pending mapping
onoremap in' :<C-u>normal! f'vi'<CR>
onoremap in" :<C-u>normal! f"vi"<CR>
onoremap in( :<C-u>normal! f(vi(<CR>
onoremap in[ :<C-u>normal! f[vi[<CR>
onoremap in{ :<C-u>normal! f{vi{<CR>
onoremap in< :<C-u>normal! f<vi<<CR>

onoremap il' :<C-u>normal! F'hvi'<CR>
onoremap il" :<C-u>normal! F"hvi"<CR>
onoremap il( :<C-u>normal! F)vi(<CR>
onoremap il[ :<C-u>normal! F[vi[<CR>
onoremap il{ :<C-u>normal! F{vi{<CR>
onoremap il< :<C-u>normal! F<vi<<CR>

" Select word with space
nnoremap <space> viw

" Swap words
nnoremap <silent> gt "_yiw:s/\(\%#\w\+\)\(\_W\+\)\(\w\+\)/\3\2\1/<CR><C-o>/\w\+\_W\+<CR><C-l>:nohlsearch<CR>

" Swap [0$] and g[0$]
nnoremap 0 g0
nnoremap $ g$
nnoremap g0 0
nnoremap g$ $

" Unmap Q and K
nnoremap Q <nop>
nnoremap K <nop>

" Y same as D or C
nnoremap Y y$

" Transform current string into a formatted one (python)
nnoremap <leader>f :normal mzF"if<Esc>`zl

" Delete last word in insert and command mode
inoremap  <C-w>
cnoremap  <C-w>

" Kill all windows except current
nnoremap <silent> <leader>o :only<CR>

" Redraw screen in insert mode
inoremap <C-l> <C-o><C-l>

" Quit visual mode with q
vnoremap q <Esc>

" Ctags
set tags=tags
nnoremap <leader>g :execute '!ctags -R .'<CR> :echo "Tags created"<CR>
" nnoremap <C-\> :tab split<CR>:exec("tag ".expand("<cword>"))<CR>
nnoremap <leader>] :vsp <CR>:exec("tag ".expand("<cword>"))<CR>


" +==============+
" |   COMMANDS   |
" +==============+

" Function to open file in split if buffer not empty
function! OpenInSplitIfNotEmpty(file)
    if line('$') == 1 && getline(1) == ''
        exec 'e' a:file
    else
        exec 'vsplit' a:file
    end
endfunction

" <C-c> to comment/uncomment
let s:comment_map = { 
            \   "bash_profile": '#',
            \   "bashrc": '#',
            \   "c": '\/\/',
            \   "cpp": '\/\/',
            \   "h": '\/\/',
            \   "profile": '#',
            \   "python": '#',
            \   "scala": '\/\/',
            \   "sh": '#',
            \   "vim": '"',
            \ }

function! ToggleComment()
    let comment_leader = get(s:comment_map, &filetype, '#')
    if getline('.') =~ "^\\s*" . comment_leader . " " 
        " Uncomment the line
        execute "silent s/^\\(\\s*\\)" . comment_leader . " /\\1/"
    else 
        if getline('.') =~ "^\\s*" . comment_leader
            " Uncomment the line
            execute "silent s/^\\(\\s*\\)" . comment_leader . "/\\1/"
        elseif getline('.') =~ "^$"
            " Don't affect empty lines
        else
            " Comment the line
            execute "silent s/^\\(\\s*\\)/\\1" . comment_leader . " /"
        end
    end
endfunction

nnoremap <silent> <C-_> :call ToggleComment()<cr>
vnoremap <silent> <C-_> :call ToggleComment()<cr>

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
if !exists(":DiffOrig")
    command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
                \ | wincmd p | diffthis
endif

if !exists(":W")
    command W w !sudo tee "%" > /dev/null
endif


" +=================+
" |   STATUS LINE   |
" +=================+

" Set status line
function! GitBranch()
    return system("git rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d '\n'")
endfunction

function! StatuslineGit()
    let l:branchname = GitBranch()
    return strlen(l:branchname) > 0?'  '.l:branchname.' ':''
endfunction

highlight StatusLineNC cterm=underline ctermfg=130
highlight StatusLine cterm=bold ctermfg=130 ctermbg=LightGray

set laststatus=2
set statusline=
set statusline+=%#PmenuSel#
set statusline+=%{StatuslineGit()}
set statusline+=%#LineNr#
set statusline+=%0*
set statusline+=\ %f
set statusline+=%m
set statusline+=%{zoom#statusline()}
set statusline+=%=
set statusline+=\ %l/%L
set statusline+=\ (%p%%)


" +===========+
" |   FIXES   |
" +===========+

" Fix Ctrl-Arrow
noremap [1;5D <C-Left>
noremap! [1;5D <C-Left>
noremap [1;5C <C-Right>
noremap! [1;5C <C-Right>

" Fix Alt shortcuts <M-key>
let c='a'
while c <= 'z'
    exec "set <M-".c.">=\e".c
    exec "imap \e".c." <M-".c.">"
    let c = nr2char(1+char2nr(c))
endw

" Toggle paste mode each time pasting from clipboard, and remove it after
" Source : https://coderwall.com/p/if9mda/automatically-set-paste-mode-in-vim-when-pasting-in-insert-mode
let &t_SI .= "\<Esc>[?2004h"
let &t_EI .= "\<Esc>[?2004l"

inoremap <special> <expr> <Esc>[200~ XTermPasteBegin()

function! XTermPasteBegin()
    set pastetoggle=<Esc>[201~
    set paste
    return ""
endfunction

" Vim diff colors
highlight DiffAdd    cterm=bold ctermfg=10 ctermbg=17
highlight DiffDelete cterm=bold ctermfg=10 ctermbg=17
highlight DiffChange cterm=bold ctermfg=10 ctermbg=17
highlight DiffText   cterm=bold ctermfg=10 ctermbg=88

