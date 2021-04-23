
" Variables {{{1
if !exists('s:toc_autoclose')
    let s:toc_autoclose = 1
endif


" Functions {{{1
function! s:TOC_ToggleAutoclose()
    let s:toc_autoclose = !s:toc_autoclose
endfunction

function! s:TOC_CRAutoclose()
    if s:toc_autoclose | lclose | endif
endfunction

function! s:TOC_ToggleZoom()
    if exists('s:toc_width')
        execute 'vertical resize ' . s:toc_width
        unlet s:toc_width
    else
        let s:toc_width = winwidth(0)
        vertical resize
    endif
endfunction

function! s:TOC_GoToBaseHeader(dir)
    let l:line_nb = line('.') + a:dir
    while 0 < l:line_nb && l:line_nb < line('$') && indent(l:line_nb) > 0
        let l:line_nb += a:dir
    endwhile

    if indent(l:line_nb) == 0
        call cursor(l:line_nb, 1)
        normal! ^
    endif
endfunction


function! s:TOC_GoToSiblingHeader(dir)
    let l:line_nb = line('.') + a:dir
    let l:indent_lvl = indent('.')
    while 0 < l:line_nb && l:line_nb < line('$') && indent(l:line_nb) > l:indent_lvl
        let l:line_nb += a:dir
    endwhile

    if indent(l:line_nb) == l:indent_lvl
        call cursor(l:line_nb, 1)
        normal! ^
    endif
endfunction


function! s:TOC_GoToParentHeader()
    let l:line_nb = line('.')
    let l:indent_lvl = indent('.')
    if l:indent_lvl == 0 | return | endif

    while l:line_nb > 0 && indent(l:line_nb) >= l:indent_lvl
        let l:line_nb -= 1
    endwhile

    if indent(l:line_nb) < l:indent_lvl-1
        call cursor(l:line_nb, 1)
        normal! ^
    endif
endfunction

augroup Toc
    autocmd! * <buffer>

    " Close markdown TOC when closing file
    autocmd BufEnter * if (winnr('$') == 1 && &filetype ==# 'toc') | q | endif
augroup END


" Mappings {{{1
nnoremap <buffer><silent> <CR> <CR>:call <SID>TOC_CRAutoclose()<CR>zvjzvzczOkzt
nnoremap <buffer><silent> <leader><CR> :execute "lclose \| botright vsplit \| " . line('.') . "ll \| normal! zOzt"<CR>

nnoremap <buffer><silent><nowait> P <nop>
nnoremap <buffer><silent><nowait> s <nop>
nnoremap <buffer><silent><nowait> i <nop>

nnoremap <buffer><silent><nowait> p <CR>zvjzvzczOkzt<C-W>p
nnoremap <buffer><silent><nowait> c :call <SID>TOC_ToggleAutoclose()<CR>
nnoremap <buffer><silent><nowait> x :call <SID>TOC_ToggleZoom()<CR>
nnoremap <buffer><silent><nowait> q :q<CR>

nnoremap <buffer><silent> ]] :call <SID>TOC_GoToBaseHeader(1)<CR>
nnoremap <buffer><silent> [[ :call <SID>TOC_GoToBaseHeader(-1)<CR>
nnoremap <buffer><silent> ][ :call <SID>TOC_GoToSiblingHeader(1)<CR>
nnoremap <buffer><silent> [] :call <SID>TOC_GoToSiblingHeader(-1)<CR>
nnoremap <buffer><silent> ]u :call <SID>TOC_GoToParentHeader()<CR>
nmap <buffer><silent> <leader>c <leader>c


" Statusline {{{1
function! StatuslineAutoclose()
    return s:toc_autoclose ? '[C] ' : ' '
endfunction

setlocal statusline=%{StatuslineAutoclose()}
setlocal statusline+=%{b:toc_filename}

set shiftwidth=2

" Modeline {{{1
" vim: foldmethod=marker
