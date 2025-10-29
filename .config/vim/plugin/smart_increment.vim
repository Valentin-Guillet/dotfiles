" This plugin improves <C-a> and <C-x> by switching between different patterns

if exists("g:loaded_smart_increment")
    finish
endif
let g:loaded_smart_increment = 1

let s:translate_list = [
    \ ['true', 'false'],
    \ ['True', 'False'],
    \ ['TRUE', 'FALSE'],
\ ]

function! s:SmartIncrement(dir)
    let line = getline('.')
    let col = getcurpos()[2]

    let min_pos = match(line, '\d', col)
    let found_pattern = ""
    let replacement = ""
    for patterns in s:translate_list
        for pattern_id in range(len(patterns))
            let pattern = patterns[pattern_id]
            let pos = match(line, '\C\<' . pattern . '\>', col - len(pattern))
            if pos > -1 && (min_pos == -1 || pos < min_pos)
                let min_pos = pos
                let found_pattern = pattern
                let replacement = patterns[(pattern_id + 1) % len(patterns)]
            endif
        endfor
    endfor

    if empty(found_pattern)
        execute "normal! " . (a:dir == 1 ? "\<C-a>" : "\<C-x>")
    else
        call cursor(0, min_pos)
        call search('\C\<' . found_pattern . '\>', 'c')
        execute "normal! ciw" . replacement
    endif

endfunction

nnoremap <silent> <C-a> :call <SID>SmartIncrement(1)<CR>
nnoremap <silent> <C-x> :call <SID>SmartIncrement(-1)<CR>
