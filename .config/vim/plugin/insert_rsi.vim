" Only keeps insert mode mappings from vim-rsi (https://github.com/tpope/vim-rsi)
" to leave command line mappings to readline.vim (https://github.com/ryvnf/readline.vim)

if exists("g:loaded_insert_rsi") || v:version < 700 || &cp
    finish
endif
let g:loaded_insert_rsi = 1

set ttimeout
if &ttimeoutlen == -1
    set ttimeoutlen=50
endif

inoremap        <C-A> <C-O>^
inoremap   <C-X><C-A> <C-A>

inoremap <expr> <C-B> col('.') == 1 ? "\<Lt>C-O>k\<Lt>C-O>$" : "\<Lt>Left>"

inoremap <expr> <C-D> col('.') > strlen(getline('.')) ? "\<Lt>C-D>" : "\<Lt>Del>"
inoremap <expr> <C-E> col('.') > strlen(getline('.'))<bar><bar>pumvisible() ? "\<Lt>C-E>" : "\<Lt>End>"
inoremap <expr> <C-F> col('.') > strlen(getline('.')) ? "\<Lt>C-F>" : "\<Lt>Right>"

function! s:MapMeta() abort
    inoremap        <M-b> <S-Left>
    inoremap        <M-f> <S-Right>
    inoremap        <M-d> <C-O>dw
    inoremap        <M-BS> <C-W>
    inoremap        <M-C-h> <C-W>
endfunction

if has("gui_running") || has('nvim')
    call s:MapMeta()
else
    silent! exe "set <F29>=\<Esc>b"
    silent! exe "set <F30>=\<Esc>f"
    silent! exe "set <F31>=\<Esc>d"
    inoremap        <F29> <S-Left>
    inoremap        <F30> <S-Right>
    inoremap        <F31> <C-O>de
    inoremap        <Esc><BS> <C-W>
    augroup rsi_gui
        autocmd GUIEnter * call s:MapMeta()
    augroup END
endif

" vim:set et sw=4:
