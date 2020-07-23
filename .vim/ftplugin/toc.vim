
function! s:MoveToParentHeader()
    let l:line_nb = line('.')
    let l:indent_lvl = indent('.')
    if !l:indent_lvl
        return
    endif

    while l:line_nb > 0 && indent(l:line_nb) >= l:indent_lvl
        let l:line_nb -= 1
    endwhile

    if indent(l:line_nb) < l:indent_lvl-1
        call cursor(l:line_nb, 1)
    endif

endfunction

function! s:MoveToSiblingHeader(dir)
    let l:line_nb = line('.') + a:dir
    let l:indent_lvl = indent('.')

    while 0 < l:line_nb && l:line_nb < line('$') && indent(l:line_nb) > l:indent_lvl
        let l:line_nb += a:dir
    endwhile

    if indent(l:line_nb) == l:indent_lvl
        call cursor(l:line_nb, 1)
    endif

endfunction

augroup Toc
    autocmd! * <buffer>

    " Close markdown TOC when closing file
    autocmd BufEnter * if (winnr('$') == 1 && &filetype ==# 'toc') | q | endif
augroup END

nnoremap <buffer><silent> <CR> <CR>:lclose<CR>zvzt
nnoremap <buffer><silent> <leader><CR> :execute "lclose \| botright vsplit \| " . line('.') . "ll \| normal! zOzt"<Cr>

nnoremap <buffer><silent> ]u :call <SID>MoveToParentHeader()<Cr>
nnoremap <buffer><silent> [[ :call <SID>MoveToSiblingHeader(-1)<Cr>
nnoremap <buffer><silent> ]] :call <SID>MoveToSiblingHeader(1)<Cr>

