" TOML folding: sections, multiline arrays, and inline tables.

function! s:TomlIsSection(line) abort
    return a:line =~# '^\s*\[\{1,2}.*\]\{1,2}\s*\%(#.*\)\?$'
endfunction


function! s:TomlBuildFolds() abort
    let l:lines = getline(1, '$')
    let l:nlines = len(l:lines)
    let l:levels = repeat([0], l:nlines)
    let l:starts = {}
    let l:stack = []
    let l:section = 0
    let l:quote = ''

    for l:lnum in range(1, l:nlines)
        let l:line = l:lines[l:lnum - 1]

        " Section headers start level-1 folds.
        if empty(l:quote) && s:TomlIsSection(l:line)
            let l:section = 1
            let l:levels[l:lnum - 1] = 1
            let l:starts[string(l:lnum)] = 1
            continue
        endif

        " Collections opened on earlier lines are already multiline.
        let l:old_depth = len(l:stack)
        let l:i = 0
        let l:len = strlen(l:line)

        while l:i < l:len
            let l:c = strpart(l:line, l:i, 1)

            " Handle strings, including multiline strings.
            if !empty(l:quote)
                if strlen(l:quote) == 3
                    if strpart(l:line, l:i, 3) ==# l:quote
                        let l:quote = ''
                        let l:i += 3
                        continue
                    elseif l:quote ==# '"""' && l:c ==# '\'
                        " Escaped character in a multiline basic string.
                        let l:i += 2
                        continue
                    endif
                else
                    if l:c ==# '\' && l:quote ==# '"'
                        let l:i += 2
                        continue
                    elseif l:c ==# l:quote
                        let l:quote = ''
                    endif
                endif

                let l:i += 1
                continue
            endif

            " Ignore comments.
            if l:c ==# '#'
                break
            endif

            " Start a string.
            if l:c ==# '"' || l:c ==# "'"
                if strpart(l:line, l:i, 3) ==# repeat(l:c, 3)
                    let l:quote = repeat(l:c, 3)
                    let l:i += 3
                else
                    let l:quote = l:c
                    let l:i += 1
                endif
                continue
            endif

            " Open an array or inline table.
            if l:c ==# '[' || l:c ==# '{'
                call add(l:stack, {
                    \ 'line': l:lnum,
                    \ 'close': l:c ==# '[' ? ']' : '}'
                    \ })
            elseif l:c ==# ']' || l:c ==# '}'
                " Close a matching collection.
                if !empty(l:stack) && l:c ==# l:stack[-1].close
                    call remove(l:stack, -1)
                endif
            endif

            let l:i += 1
        endwhile

        " Single-line strings cannot continue onto the next line.
        if strlen(l:quote) == 1
            let l:quote = ''
        endif

        " Collections remaining on the stack at the end of this line
        " include any multiline collections opened on this line.
        let l:depth = len(l:stack)
        let l:level = l:section + max([l:old_depth, l:depth])
        let l:levels[l:lnum - 1] = l:level

        " Mark the beginning of a multiline collection fold.
        if l:depth > 0
            for l:item in l:stack
                if l:item.line == l:lnum
                    let l:starts[string(l:lnum)] = l:level
                    break
                endif
            endfor
        endif
    endfor

    let b:toml_fold_levels = l:levels
    let b:toml_fold_starts = l:starts
    let b:toml_fold_tick = b:changedtick
endfunction


function! TomlFoldExpr(lnum) abort
    if !exists('b:toml_fold_tick')
                \ || b:toml_fold_tick != b:changedtick
        call s:TomlBuildFolds()
    endif

    let l:key = string(a:lnum)

    if has_key(b:toml_fold_starts, l:key)
        return '>' . b:toml_fold_starts[l:key]
    endif

    return b:toml_fold_levels[a:lnum - 1]
endfunction


setlocal foldmethod=expr
setlocal foldexpr=TomlFoldExpr(v:lnum)
setlocal foldlevel=0
