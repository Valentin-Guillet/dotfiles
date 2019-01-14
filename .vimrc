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
set history=50		" keep 50 lines of command line history
set ruler		" show the cursor position all the time
set showcmd		" display incomplete commands
set incsearch		" do incremental searching

" Don't use Ex mode, use Q for formatting
map Q gq

" CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first break undo,
" so that you can undo CTRL-U after inserting a line break.
inoremap <C-U> <C-G>u<C-U>

" In many terminal emulators the mouse works just fine, thus enable it.
if has('mouse')
  set mouse=a
endif

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
  syntax on
  set hlsearch
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
    \   "c": '\/\/',
    \   "cpp": '\/\/',
    \   "h": '\/\/',
    \   "python": '#',
    \   "sh": '#',
    \   "profile": '#',
    \   "bashrc": '#',
    \   "bash_profile": '#',
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

set expandtab
set smarttab

set shiftwidth=4
set tabstop=4
set shiftround

set autoindent
set smartindent

set foldmethod=indent
autocmd BufRead * normal zR

set nohlsearch

nnoremap <C-c> :call ToggleComment()<cr>
vnoremap <C-c> :call ToggleComment()<cr>

" User mappings
inoremap kj <Esc>l
inoremap Kj <Esc>l
inoremap kJ <Esc>l
inoremap KJ <Esc>l
nnoremap <C-j> <C-e>
inoremap <C-j> <C-x><C-e>
nnoremap <C-k> <C-y>
inoremap <C-k> <C-x><C-y>
nnoremap <C-h> o<Esc>
nnoremap <C-n> :noh<Return>

" Vim/Tmux navigator
so ~/.config/tmux/tmux_navigator.vim


