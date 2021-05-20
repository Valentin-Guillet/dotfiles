
let s:save_cpo = &cpoptions
set cpoptions&vim

let s:has_current_match = 0
let s:try_set_hlsearch = 0

function! better_search#search(search_command)
    if s:pattern_not_found()
        let v:errmsg = ""
    endif
    let s:try_set_hlsearch = 1
    call s:set_nohlsearch()
    call s:register_autocmds()
    call feedkeys(a:search_command, 'nti')
endfunction


function! s:pattern_not_found()
    return (v:errmsg =~# '^E486')
endfunction


function! s:register_autocmds()
    augroup better_search_hl
        autocmd!
        autocmd CursorMoved,InsertEnter * call <SID>toggle_hlsearch()
    augroup END
endfunction


function! s:unregister_autocmds()
    autocmd! better_search_hl
    augroup! better_search_hl
endfunction


function! better_search#search_next_end()
    call s:register_autocmds()
    call s:set_hlsearch()
    let s:try_set_hlsearch = 0
    call better_search#print_matches()
endfunction


function! better_search#search_star()
    let s:save_shortmess = &shortmess
    let s:save_winview = winsaveview()
    set shortmess+=s
endfunction


function! better_search#search_visual_star(search_type)
    let save_yank_register_info = ['0', getreg('0'), getregtype('0')]
    let save_unnamed_register_info = ['"', getreg('"'), getregtype('"')]
    normal! gvy
    let escape_chars = '\' . a:search_type
    let search_term = '\V' . s:remove_null_bytes(escape(@@, escape_chars))
    call better_search#search_star()
    call call("setreg", save_unnamed_register_info)
    call call("setreg", save_yank_register_info)

    " since each call inserts at the start of the buffer, the characters from
    " the first call will be processed after those from the second
    call feedkeys("\<Plug>BetterSearch_visual_search_end", "mi")
    call feedkeys(a:search_type . search_term . "\<CR>N", "nti")
    call better_search#print_matches()
endfunction


function! s:remove_null_bytes(string)
    return substitute(a:string, '\%x00', '\\n', 'g')
endfunction


function! better_search#search_star_end()
    let &shortmess = s:save_shortmess
    let s:save_winview.lnum = line(".")
    let s:save_winview.col = col(".") - 1
    let s:save_winview.coladd = 0
    call winrestview(s:save_winview)
    call s:register_autocmds()
    call s:set_hlsearch()
    call better_search#print_matches()
    let s:try_set_hlsearch = 0
endfunction


" there are 3 scenarios where the cursor can move after a search is attempted:
"   1) search was successfully executed and cursor moves to next match
"   2) search was exectued but failed with a 'pattern not found' error
"   3) search was aborted by pressing <Esc> or <C-C> at the search prompt
" only want to enable highlighting for scenario 1 and ignore 2/3 entirely
function! s:toggle_hlsearch()
    if s:try_set_hlsearch
        let s:try_set_hlsearch = 0
        if !s:pattern_not_found() && s:search_executed()
            call s:set_hlsearch()
        endif
    else
        call s:set_nohlsearch()
        call s:unregister_autocmds()
    endif
endfunction


function! s:search_executed()
    let [search_pattern, offset] = s:last_search_attempt()
    let match_at_cursor = s:match_at_cursor(search_pattern, offset)
    try
        return (search_pattern ==# @/) && search(match_at_cursor, 'cnw')
    catch
        return 0
    endtry
endfunction


" extracts pattern and offset from last search attempt
function! s:last_search_attempt()
    let last_search_attempt = histget("search", -1)
    let search_dir = (v:searchforward ? "/" : "?")
    let reused_latest_pattern = (last_search_attempt[0] ==# search_dir)
    if reused_latest_pattern
        return [@/, last_search_attempt[1:]]
    endif

    let is_conjunctive_search = (last_search_attempt =~# '\\\@<![/?];[/?]')
    if is_conjunctive_search
        let search_query = matchstr(last_search_attempt, '\%(.*\\\@<![/?];\)\zs.*')
        let search_dir = search_query[0]
        let last_search_attempt = search_query[1:]
    endif
    let offset_regex = '\\\@<!'.search_dir.'[esb]\?[+-]\?[0-9]*'
    let search_pattern = matchstr(last_search_attempt, '^.\{-\}\ze\%('.offset_regex.'\)\?$')
    let offset = matchstr(last_search_attempt, offset_regex.'$')[1:]
    return [search_pattern, offset]
endfunction


" Returns a pattern string to match the search_pattern+offset at the current
" cursor position
function! s:match_at_cursor(search_pattern, offset)
    let search_pattern = s:sanitize_search_pattern(a:search_pattern)
    if empty(a:offset)
        return s:simple_match_at_cursor(search_pattern)
    elseif s:is_linewise_offset(a:offset)
        return s:linewise_match_at_cursor(search_pattern, a:offset)
    else
        return s:characterwise_match_at_cursor(search_pattern, a:offset)
    endif
endfunction


function! s:sanitize_search_pattern(search_pattern)
    let star_replacement = &magic ? '\\*' : '*'
    let equals_replacement = '\%(=\)'
    let sanitized = substitute(a:search_pattern, '\V\^*', star_replacement, '')
    return substitute(sanitized, '\V\^=', equals_replacement, '')
endfunction


function! s:simple_match_at_cursor(search_pattern)
    return a:search_pattern =~# '\\zs'
                \ ? s:normalize_zs_pattern(a:search_pattern)
                \ : '\%#' . a:search_pattern
endfunction


function! s:normalize_zs_pattern(search_pattern)
    let [head, tail] = split(a:search_pattern, '\\zs')
    return '\m\%('.head.'\m\)\@<=\%#'.s:extract_magic(head).tail
endfunction


function! s:extract_magic(search_pattern)
    let sanitized_search_pattern = substitute(a:search_pattern, '\\\\', '', 'g')
    let last_magic_pattern_regex = '\%(\\[mvMV]\)\ze\%([^\\]\|\\[^mMvV]\)*$'
    let last_magic_pattern = matchstr(sanitized_search_pattern, last_magic_pattern_regex)
    return !empty(last_magic_pattern) ? last_magic_pattern : s:magic()
endfunction


function! s:magic()
    return &magic ? '\m' : '\M'
endfunction


function! s:is_linewise_offset(offset)
    return a:offset[0] !~# '[esb]'
endfunction


function! s:linewise_match_at_cursor(search_pattern, offset)
    let cursor_line = line(".")
    let offset_lines = matchstr(a:offset, '\d\+')
    let offset_lines = !empty(offset_lines) ? str2nr(offset_lines) : 1
    if (a:offset =~ '^-')
        return '\m\%(\%#' . repeat('.*\n', offset_lines) . '.*\)\@<=' . s:magic() . a:search_pattern
    else
        return a:search_pattern . '\m\%(' . repeat('.*\n', offset_lines) . '\%#\)\@='
    endif
endfunction


function! s:characterwise_match_at_cursor(search_pattern, offset)
    let cursor_column = s:offset_cursor_column(a:search_pattern, a:offset)
    if cursor_column == 0
        return s:simple_match_at_cursor(a:search_pattern)
    elseif cursor_column < 0
        let offset = (0 - cursor_column)
        return '\%(\%#' . repeat('\_.', offset) . '\)\@<=' . a:search_pattern
    elseif cursor_column >= strchars(a:search_pattern)
        let offset = cursor_column - strchars(a:search_pattern)
        return a:search_pattern . '\m\%(' . repeat('\_.', offset) . '\%#\)\@='
    endif
    let byteidx = byteidx(a:search_pattern, cursor_column)
    let start = a:search_pattern[0 : byteidx - 1]
    let end = a:search_pattern[byteidx : -1]
    return start . '\%#' . s:sanitize_search_pattern(end)
endfunction


function! s:offset_cursor_column(search_pattern, offset)
    let default_offset = (a:offset =~ '[-+]') ? 1 : 0
    let offset_chars = matchstr(a:offset, '\d\+')
    let offset_chars = !empty(offset_chars) ? str2nr(offset_chars) : default_offset
    let start_column = (a:offset =~ 'e') ? strchars(a:search_pattern) - 1 : 0
    return a:offset =~ '-' ? (start_column - offset_chars) : (start_column + offset_chars)
endfunction


function! s:set_hlsearch()
    set hlsearch
    call s:highlight_current_match()
    if (&foldopen =~# 'search') || (&foldopen =~# 'all')
        normal! zv
    endif
endfunction


function! s:set_nohlsearch()
    set nohlsearch
    call s:clear_current_match()
endfunction


function! s:highlight_current_match() abort
    call s:clear_current_match()
    let [search_pattern, offset] = s:last_search_attempt()
    let match_at_cursor = s:match_at_cursor(search_pattern, offset)
    let w:better_search_current_match = matchadd("IncSearch", s:magic().'\c'.match_at_cursor, 999)
    let s:has_current_match = 1
endfunction


function! s:clear_current_match()
    if s:has_current_match
        let [current_match_tabnr, current_match_winnr] = s:find_current_match_window()
        if (current_match_tabnr > 0) && (current_match_winnr > 0)
            let save_tab = tabpagenr()
            let save_win = tabpagewinnr(current_match_tabnr)
            execute "tabnext" current_match_tabnr
            execute current_match_winnr "wincmd w"

            call s:matchdelete(w:better_search_current_match)
            unlet w:better_search_current_match

            execute save_win "wincmd w"
            execute "tabnext" save_tab
        elseif exists("w:better_search_current_match")
            " ensure current match is cleared in special cases like command line window
            call s:matchdelete(w:better_search_current_match)
            unlet w:better_search_current_match
        endif
        let s:has_current_match = 0
    endif
endfunction


function! better_search#clear_all()
    call s:set_nohlsearch()
endfunction


function! s:find_current_match_window()
    if !empty(getcmdwintype())
        return [-1, -1]
    endif

    for winnr in range(1, winnr("$"))
        if !empty(getwinvar(winnr, "better_search_current_match"))
            return [tabpagenr(), winnr]
        endif
    endfor

    for tabnr in range(1, tabpagenr("$"))
        for winnr in range(1, tabpagewinnr(tabnr, "$"))
            if !empty(gettabwinvar(tabnr, winnr, "better_search_current_match"))
                return [tabnr, winnr]
            endif
        endfor
    endfor

    return [-1, -1]
endfunction


function! s:matchdelete(match_id)
    try
        call matchdelete(a:match_id)
    catch /E803/
        " suppress errors for matches that have already been deleted
    endtry
endfunction

" Search index
function! s:matches_in_range(range)
    " Use :s///n to search efficiently in large files. Although calling search()
    " in the loop would be cleaner (see issue #18), it is also much slower.
    let gflag = &gdefault ? '' : 'g'
    let saved_marks = [ getpos("'["), getpos("']") ]
    let output = ''
    redir => output
    silent! execute 'keepjumps ' . a:range . 's//~/en' . gflag
    redir END
    call setpos("'[", saved_marks[0])
    call setpos("']", saved_marks[1])
    return str2nr(matchstr(output, '\d\+'))
endfunction

" Calculate which match in the current line the 'col' is at.
function! s:match_in_line()
    let line = line('.')
    let col = col('.')

    normal! 0
    let matches = 0
    let s_opt = 'c'
    " The count might be off in edge cases (e.g. regexes that allow empty match,
    " like 'a*'). Unfortunately, Vim's searching functions are so inconsistent
    " that I can't fix this.
    " if @/ ==# ''
    "     let @/ = ' '
    " endif
    try
        while search(@/, s_opt, line) && col('.') <= col
            let matches += 1
            let s_opt = ''
        endwhile
    catch
    endtry

    return matches
endfunction

" Efficiently recalculate number of matches above cursor using values cached
" from the previous run.
function s:matches_above(cached_values)
    " avoid wrapping range at the beginning of file
    if line('.') == 1 | return 0 | endif

    let [old_line, old_result, total] = a:cached_values
    " Find the nearest point from which we can restart match counting (top,
    " bottom, or previously cached line).
    let line = line('.')
    let to_top = line
    let to_old = abs(line - old_line)
    let to_bottom = line('$') - line
    let min_dist = min([to_top, to_old, to_bottom])

    if min_dist == to_top
        return s:matches_in_range('1,.-1')
    elseif min_dist == to_bottom
        return total - s:matches_in_range(',$')
        " otherwise, min_dist == to_old, we just need to check relative line order
    elseif old_line < line
        return old_result + s:matches_in_range(old_line . ',-1')
    elseif old_line > line
        return old_result - s:matches_in_range(',' . (old_line - 1))
    else " old_line == line
        return old_result
    endif
endfunction

" Return the given string, shortened to the maximum length. The middle of the
" string would be replaced by '...' in case the original string is too long.
function! s:short_string(string, max_length)
    if len(a:string) < a:max_length
        return a:string
    endif

    " Calculate the needed length of each part of the string.
    " The 3 is because the middle part would be replace with 3 points.
    let l:string_part_length = (a:max_length - 3) / 2

    let l:start = a:string[:l:string_part_length - 1]
    let l:end = a:string[len(a:string) - l:string_part_length:]

    let l:output_string = l:start . "..." . l:end

    return l:output_string
endfunction

function! better_search#print_matches()
    let l:dir_char = v:searchforward ? '/' : '?'
    if line('$') > g:better_search_line_limit
        let l:msg = '[MAX]  ' . l:dir_char . @/
    else
        " If there are no matches, search fails before we get here. The only way
        " we could see zero results is on 'g/' (but that's a reasonable result).
        let [l:current, l:total] = s:match_counts()
        let l:msg = '[' . l:current . '/' . l:total . ']  ' . l:dir_char . @/
    endif

    " foldopen+=search causes search commands to open folds in the matched line
    " - but it doesn't work in mappings. Hence, we just open the folds here.
    if &foldopen =~# "search"
        normal! zv
    endif

    " Shorten the message string, to make it one screen wide. Do it only if the
    " T flag is inside the shortmess variable.
    " It seems that the press enter message won't be printed only if the length
    " of the message is shorter by at least 11 chars than the real length of the
    " screen.
    if &shortmess =~# "T"
        let l:msg = s:short_string(l:msg, &columns - 11)
    endif

    " Flush any delayed screen updates before printing "l:msg".
    " See ":h :echo-redraw".
    redraw | echo l:msg
endfunction

" Return 2-element array, containing current index and total number of matches
" of @/ (last search pattern) in the current buffer.
function! s:match_counts()
    " both :s and search() modify cursor position
    let win_view = winsaveview()
    " folds affect range of ex commands (issue #4)
    let save_foldenable = &foldenable
    set nofoldenable

    let in_line = s:match_in_line()

    let cache_key = [b:changedtick, @/]
    if exists('b:better_search_cache_key') && b:better_search_cache_key ==# cache_key
        let before = s:matches_above(b:better_search_cache_val)
        let total = b:better_search_cache_val[-1]
    else
        let before = (line('.') == 1 ? 0 : s:matches_in_range('1,-1'))
        let total = before + s:matches_in_range(',$')
    endif

    let b:better_search_cache_val = [line('.'), before, total]
    let b:better_search_cache_key = cache_key

    let &foldenable = save_foldenable
    call winrestview(win_view)

    return [before + in_line, total]
endfunction


let &cpoptions = s:save_cpo
unlet s:save_cpo
