
if exists("g:loaded_better_search")
    finish
endif
let g:loaded_better_search = 1

"Options
let s:save_cpo = &cpoptions
set cpoptions&vim
set nohlsearch

if !exists('g:better_search_line_limit')
    let g:better_search_line_limit=1000000
endif

" Plug mappings
nnoremap <silent> <Plug>BetterSearch_/ :call better_search#search('/')<CR>
nnoremap <silent> <Plug>BetterSearch_? :call better_search#search('?')<CR>

nnoremap <silent> <Plug>BetterSearch_n n:call better_search#search_next_end()<CR>
nnoremap <silent> <Plug>BetterSearch_N N:call better_search#search_next_end()<CR>

nnoremap <silent> <Plug>BetterSearch_*  :call better_search#search_star()<CR>*:call better_search#search_star_end()<CR>
nnoremap <silent> <Plug>BetterSearch_#  :call better_search#search_star()<CR>#:call better_search#search_star_end()<CR>
nnoremap <silent> <Plug>BetterSearch_g* :call better_search#search_star()<CR>g*:call better_search#search_star_end()<CR>
nnoremap <silent> <Plug>BetterSearch_g# :call better_search#search_star()<CR>g#:call better_search#search_star_end()<CR>
nnoremap <silent> <Plug>BetterSearch_gd :call better_search#search_star()<CR>gd:call better_search#search_star_end()<CR>
nnoremap <silent> <Plug>BetterSearch_gD :call better_search#search_star()<CR>gD:call better_search#search_star_end()<CR>
nnoremap <silent> <Plug>BetterSearch_g/ :call better_search#search_next_end()<CR>

xnoremap <silent> <Plug>BetterSearch_* <Esc>:<C-U>call better_search#search_visual_star('/')<CR>
xnoremap <silent> <Plug>BetterSearch_# <Esc>:<C-U>call better_search#search_visual_star('?')<CR

" hack used to call better_search#better_search_star_end from feedkeys without causing
" command to echo or be saved in command history
nnoremap <silent> <Plug>BetterSearch_visual_search_end :<C-U>call better_search#search_star_end()<CR>


silent! cmap <unique><expr> <CR>
            \ "\<CR>" . (getcmdtype() =~ '[/?]' ? ":call better_search#print_matches()<CR>" : "")

if exists('*getcmdwintype')
    augroup searchindex_cmdwin
        autocmd!
        " WARNING: don't add a space between the <CR> and the | at the risk of breaking everything
        autocmd CmdWinEnter * if getcmdwintype() =~ '[/?]' | silent! nnoremap <buffer> <CR> <CR>:call better_search#print_matches()<CR>| endif
    augroup END
endif



" Mappings
for key in ['/', '?', 'n', 'N', '*', '#', 'g*', 'g#', 'gd', 'gD', 'g/']
    if !hasmapto(printf("<Plug>BetterSearch_%s", key), "n")
        execute printf("nmap %s <Plug>BetterSearch_%s", key, key)
    endif
endfor

for key in ['*', '#']
    if !hasmapto(printf("<Plug>BetterSearch_%s", key), "v")
        execute printf("xmap %s <Plug>BetterSearch_%s", key, key)
    endif
endfor

" Clear match when redrawing screen
nnoremap <silent> <C-l> <C-l>:call better_search#clear_all()<CR>


function! s:FrequencyCount(...)
    let l:saved_search = @/
    let l:word = (a:0 ? a:1 : expand("<cword>"))
    let @/ = l:word

    silent! unlet b:better_search_cache_key
    let [l:current, l:total] = better_search#match_counts()
    echom l:word . ": [" . l:current . "/" . l:total . "]"

    let @/ = l:saved_search
endfunction

if !exists(":Freq")
    command -bar -nargs=? Freq call <SID>FrequencyCount(<f-args>)
endif


let &cpoptions = s:save_cpo
unlet s:save_cpo
