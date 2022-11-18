" This plugin is a merge between vim-evanesco (https://github.com/pgdouyon/vim-evanesco)
" and vim-searchindex (https://github.com/google/vim-searchindex)
"
" Evanesco automatically clears search highlight whenever the cursor moves or
" insert mode is entered
"
" Searchindex shows how many times a search pattern occurs in the current
" buffer (same as `set shortmessage-=S`, but without a limit of 99 and
" displayed right next to the search term)

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
    augroup searchindexCmdwin
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


function! s:FrequencyCount(search_words, ...)
    let l:word = (a:0 ? a:1 : expand("<cword>"))
    if a:search_words | let l:word = "\\<" . l:word . "\\>" | endif
    let @/ = l:word
    call better_search#search_next_end()
endfunction

if !exists(":Freq")
    command -bar -nargs=? Freq call <SID>FrequencyCount(0, <f-args>)
endif
if !exists(":Freqw")
    command -bar -nargs=? Freqw call <SID>FrequencyCount(1, <f-args>)
endif


" Set hlsearch when searching to see all matches
augroup incsearch_highlight
    autocmd!
    autocmd CmdlineEnter /,\? :set hlsearch
    autocmd CmdlineLeave /,\? :set nohlsearch
augroup END


let &cpoptions = s:save_cpo
unlet s:save_cpo
