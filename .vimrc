" Define leader
let mapleader = ","

" Edit and reload vim config with <leader>[e|s]v
nnoremap <leader>e :vsplit $MYVIMRC<CR>
nnoremap <leader>r :source $MYVIMRC<CR>:echo "Config reloaded !"<CR>

" Write file with <leader>w
nnoremap <leader>w :update <CR>

" Split
nnoremap <leader>\ :vsplit<CR>
nnoremap <leader>- :split<CR>
nnoremap <leader>= <C-w>=
nnoremap <leader>q :q<CR>

" Resize splits
source ~/.config/vim/submode.vim
call submode#set_resize_mode()
let g:submode_timeout = 0

" Tabs
nnoremap <leader>t :tabnew<CR>
nnoremap <leader>n :tabnext<CR>
nnoremap <leader>p :tabprev<CR>

" Scroll with C-[j|k]
nnoremap <C-j> <C-e>
inoremap <C-j> <C-x><C-e>
nnoremap <C-k> <C-y>
inoremap <C-k> <C-x><C-y>

" Exit insert mode with kj
inoremap kj <Esc>l
inoremap Kj <Esc>l
inoremap kJ <Esc>l
inoremap KJ <Esc>l
vnoremap kj <Esc>
vnoremap Kj <Esc>
vnoremap kJ <Esc>
vnoremap KJ <Esc>

" Move line
nnoremap - ddp
nnoremap _ ddkP

" Add a new line
nnoremap <C-h> o<Esc>

" Select word with space
nnoremap <space> viw

" Transform current string into a formatted one (python)
nnoremap <leader>f :normal mzF"if<Esc>`zl

" Surround words
nnoremap <leader>' viw<Esc>a'<Esc>bi'<Esc>lel
nnoremap <leader>" viw<Esc>a"<Esc>bi"<Esc>lel
nnoremap <leader>( viw<Esc>a)<Esc>bi(<Esc>lel
nnoremap <leader>[ viw<Esc>a]<Esc>bi[<Esc>lel
nnoremap <leader>{ viw<Esc>a}<Esc>bi{<Esc>lel
nnoremap <leader>< viw<Esc>a><Esc>bi<<Esc>lel

vnoremap <leader>' <Esc>`>a'<Esc>`<i'<Esc>
vnoremap <leader>" <Esc>`>a"<Esc>`<i"<Esc>
vnoremap <leader>( <Esc>`>a)<Esc>`<i(<Esc>
vnoremap <leader>[ <Esc>`>a]<Esc>`<i[<Esc>
vnoremap <leader>{ <Esc>`>a}<Esc>`<i{<Esc>
vnoremap <leader>< <Esc>`>a><Esc>`<i<<Esc>

" Operator pending mapping
onoremap in' :<C-u>normal! f'vi'<Cr>
onoremap in" :<C-u>normal! f"vi"<Cr>
onoremap in( :<C-u>normal! f(vi(<Cr>
onoremap in[ :<C-u>normal! f[vi[<Cr>
onoremap in{ :<C-u>normal! f{vi{<Cr>
onoremap in< :<C-u>normal! f<vi<<Cr>

onoremap il' :<C-u>normal! F'hvi'<Cr>
onoremap il" :<C-u>normal! F"hvi"<Cr>
onoremap il( :<C-u>normal! F)vi(<Cr>
onoremap il[ :<C-u>normal! F[vi[<Cr>
onoremap il{ :<C-u>normal! F{vi{<Cr>
onoremap il< :<C-u>normal! F<vi<<Cr>

" Use Vim settings, rather than Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

if has("vms")
    set nobackup		" do not keep a backup file, use versions instead
else
    set backup		" keep a backup file (restore to previous version)
    set undofile		" keep an undo file (undo changes after closing)
endif
set history=50	    " keep 50 lines of command line history
set ruler           " show the cursor position all the time
set showcmd	        " display incomplete commands
set incsearch       " do incremental searching

if has('mouse')
    set mouse=a
endif

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
    syntax on
endif

" Only do this part when compiled with support for autocommands.
if has("autocmd")

    " Enable file type detection.
    " Use the default filetype settings, so that mail gets 'tw' set to 72,
    " 'cindent' is on in C files, etc.
    " Also load indent files, to automatically do language-dependent indenting.
    filetype plugin indent on

    " Put these in an autocmd group, so that we can delete them easily.
    augroup vimrcEx
        au!

        " For all text files set 'textwidth' to 78 characters.
        autocmd FileType text setlocal textwidth=78

        " When editing a file, always jump to the last known cursor position.
        " Don't do it when the position is invalid or when inside an event handler
        " (happens when dropping a file on gvim).
        autocmd BufReadPost *
                    \ if line("'\"") >= 1 && line("'\"") <= line("$") |
                    \   exe "normal! g`\"" |
                    \ endif

    augroup END

else

    set autoindent		" always set autoindenting on

endif " has("autocmd")

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
if !exists(":DiffOrig")
    command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
                \ | wincmd p | diffthis
endif

if has('langmap') && exists('+langnoremap')
    " Prevent that the langmap option applies to characters that result from a
    " mapping.  If unset (default), this may break plugins (but it's backward
    " compatible).
    set langnoremap
endif


" Add optional packages.
"
" The matchit plugin makes the % command work better, but it is not backwards
" compatible.
try
    packadd matchit
catch /.*/
endtry


if !isdirectory($HOME . "/.vim/backup")
    call mkdir($HOME . "/.vim/backup", "p")
endif
if !isdirectory($HOME . "/.vim/swap")
    call mkdir($HOME . "/.vim/swap", "p")
endif
if !isdirectory($HOME . "/.vim/undo")
    call mkdir($HOME . "/.vim/undo", "p")
endif

set backupdir=~/.vim/backup//,/tmp//
set directory=~/.vim/swap//,/tmp//
set undodir=~/.vim/undo//,/tmp//


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

" Fix Alt shortcuts <M-key>
let c='a'
while c <= 'z'
    exec "set <M-".c.">=\e".c
    exec "imap \e".c." <M-".c.">"
    let c = nr2char(1+char2nr(c))
endw

set timeout ttimeoutlen=50

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

set splitbelow
set splitright

set expandtab
set smarttab

set shiftwidth=4
set tabstop=4
set shiftround

set autoindent
set smartindent

set nohlsearch

nnoremap <silent> <C-c> :call ToggleComment()<cr>
vnoremap <silent> <C-c> :call ToggleComment()<cr>


if !exists(":W")
    command W w !sudo tee "%" > /dev/null
endif

" Vim/Tmux navigator
source ~/.config/tmux/tmux_navigator.vim
let g:tmux_navigator_disable_when_zoomed = 1

" Vim zoom pane
source ~/.config/tmux/zoom.vim
nnoremap <silent> <leader>z :call zoom#toggle()<cr>

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

