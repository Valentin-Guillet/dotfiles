
"Plugin startup code
if !exists('g:todolists_plugin')
    let g:todolists_plugin = 1

    if exists('todolists_auto_commands')
        echoerr 'TodoLists: todolists_auto_commands group already exists'
        exit
    endif
endif


" Sets the item done
function! s:TodoListsSetItemDone(lineno)
    let l:line = getline(a:lineno)
    call setline(a:lineno, substitute(l:line, '^\(\s*- \)\[ \]', '\1[X]', ''))
endfunction


" Sets the item not done
function! s:TodoListsSetItemNotDone(lineno)
    let l:line = getline(a:lineno)
    call setline(a:lineno, substitute(l:line, '^\(\s*- \)\[X\]', '\1[ ]', ''))
endfunction


" Checks that line is a todo list item
function! s:TodoListsLineIsItem(line)
    return a:line =~ '^\s*- \[[ X]\].*'
endfunction


" Checks that item is not done
function! s:TodoListsItemIsNotDone(line)
    if match(a:line, '^\s*- \[ \].*') != -1
        return 1
    endif

    return 0
endfunction


" Checks that item is done
function! s:TodoListsItemIsDone(line)
    if match(a:line, '^\s*- \[X\].*') != -1
        return 1
    endif

    return 0
endfunction


" Returns the line number of the brother item in specified range
function! s:TodoListsBrotherItemInRange(line, range)
    let l:indent = s:TodoListsCountLeadingSpaces(getline(a:line))
    let l:result = -1

    for current_line in a:range
        if s:TodoListsLineIsItem(getline(current_line)) == 0
            break
        endif

        if (s:TodoListsCountLeadingSpaces(getline(current_line)) == l:indent)
            let l:result = current_line
            break
        elseif (s:TodoListsCountLeadingSpaces(getline(current_line)) > l:indent)
            continue
        else
            break
        endif
    endfor

    return l:result
endfunction


" Finds the insert position above the item
function! s:TodoListsFindTargetPositionUp(lineno)
    let l:range = range(a:lineno, 1, -1)
    let l:candidate_line = s:TodoListsBrotherItemInRange(a:lineno, l:range)
    let l:target_line = -1

    while l:candidate_line != -1
        let l:target_line = l:candidate_line
        let l:candidate_line = s:TodoListsBrotherItemInRange(
                    \ l:candidate_line, range(l:candidate_line - 1, 1, -1))

        if l:candidate_line != -1 &&
                    \ s:TodoListsItemIsNotDone(getline(l:candidate_line)) == 1
            let l:target_line = l:candidate_line
            break
        endif
    endwhile

    return s:TodoListsFindLastChild(l:target_line)
endfunction


" Finds the insert position below the item
function! s:TodoListsFindTargetPositionDown(line)
    let l:range = range(a:line, line('$'))
    let l:candidate_line = s:TodoListsBrotherItemInRange(a:line, l:range)
    let l:target_line = -1

    while l:candidate_line != -1
        let l:target_line = l:candidate_line
        let l:candidate_line = s:TodoListsBrotherItemInRange(
                    \ l:candidate_line, range(l:candidate_line + 1, line('$')))
    endwhile

    return s:TodoListsFindLastChild(l:target_line)
endfunction


" Counts the number of leading spaces
function! s:TodoListsCountLeadingSpaces(line)
    return (strlen(a:line) - strlen(substitute(a:line, '^\s*', '', '')))
endfunction


" Returns the line number of the parent
function! s:TodoListsFindParent(lineno)
    let l:indent = s:TodoListsCountLeadingSpaces(getline(a:lineno))
    let l:parent_lineno = -1

    for current_line in range(a:lineno, 1, -1)
        if (s:TodoListsLineIsItem(getline(current_line)) &&
                    \ s:TodoListsCountLeadingSpaces(getline(current_line)) < l:indent)
            let l:parent_lineno = current_line
            break
        endif
    endfor

    return l:parent_lineno
endfunction


" Returns the line number of the last child
function! s:TodoListsFindLastChild(lineno)
    let l:indent = s:TodoListsCountLeadingSpaces(getline(a:lineno))
    let l:last_child_lineno = a:lineno

    " If item is the last line in the buffer it has no children
    if a:lineno == line('$')
        return l:last_child_lineno
    endif

    for current_line in range (a:lineno + 1, line('$'))
        if (s:TodoListsLineIsItem(getline(current_line)) &&
                    \ s:TodoListsCountLeadingSpaces(getline(current_line)) > l:indent)
            let l:last_child_lineno = current_line
        else
            break
        endif
    endfor

    return l:last_child_lineno
endfunction


" Marks the parent done if all children are done
function! s:TodoListsUpdateParent(lineno)
    if s:disable_undo
        return
    endif

    let l:parent_lineno = s:TodoListsFindParent(a:lineno)

    " No parent item
    if l:parent_lineno == -1
        return
    endif

    let l:last_child_lineno = s:TodoListsFindLastChild(l:parent_lineno)

    " There is no children
    if l:last_child_lineno == l:parent_lineno
        return
    endif

    for current_line in range(l:parent_lineno + 1, l:last_child_lineno)
        if s:TodoListsItemIsNotDone(getline(current_line)) == 1
            " Not all children are done
            call s:TodoListsSetItemNotDone(l:parent_lineno)
            call s:TodoListsUpdateParent(l:parent_lineno)
            return
        endif
    endfor

    call s:TodoListsSetItemDone(l:parent_lineno)
    call s:TodoListsUpdateParent(l:parent_lineno)
endfunction

function! s:TodoListsUpdateItems(lineno)
    call s:TodoListsUpdateParent(a:lineno-1)
    call s:TodoListsUpdateParent(a:lineno)
endfunction

" Applies the function for each child
function! s:TodoListsForEachChild(lineno, function)
    let l:last_child_lineno = s:TodoListsFindLastChild(a:lineno)

    " Apply the function on children prior to the item.
    " This order is required for proper work of the items moving on toggle
    for current_line in range(a:lineno, l:last_child_lineno)
        call call(a:function, [current_line])
    endfor
endfunction


" Sets mapping for normal navigation and editing mode
function! s:TodoListsSetNormalMode()
    nunmap <buffer> o
    nunmap <buffer> O
    nunmap <buffer> j
    nunmap <buffer> k
    nunmap <buffer> dd
    nnoremap <silent> <buffer> <Space> :call <SID>TodoListsToggleItem()<CR>
    vnoremap <silent> <buffer> <Space> :'<,'>call <SID>TodoListsToggleItem()<CR>
    noremap  <silent> <buffer> <leader>e :call <SID>TodoListsSetItemMode()<CR>
endfunction


" Sets mappings for faster item navigation and editing
function! s:TodoListsSetItemMode()
    nnoremap <silent> <buffer> o :call <SID>TodoListsCreateNewItemBelow()<CR>
    nnoremap <silent> <buffer> O :call <SID>TodoListsCreateNewItemAbove()<CR>
    nnoremap <silent> <buffer> j :call <SID>TodoListsGoToNextItem()<CR>
    nnoremap <silent> <buffer> k :call <SID>TodoListsGoToPreviousItem()<CR>
    nnoremap <silent> <buffer> dd :call <SID>TodoListsDeleteItem(line('.'))<CR>
    nnoremap <silent> <buffer> <leader>c :call <SID>TodoListsCleanItemsDone()<CR>
    nnoremap <silent> <buffer> <Space> :call <SID>TodoListsToggleItem()<CR>
    vnoremap <silent> <buffer> <Space> :call <SID>TodoListsToggleItem()<CR>
    inoremap <silent> <buffer> <CR> <CR><ESC>d0:call <SID>TodoListsCreateNewItem()<CR>
    noremap  <silent> <buffer> <leader>e :silent call <SID>TodoListsSetNormalMode()<CR>
    nnoremap <silent> <buffer> <Tab> :call <SID>TodoListsIncreaseIndent()<CR>
    nnoremap <silent> <buffer> <S-Tab> :call <SID>TodoListsDecreaseIndent()<CR>
    vnoremap <silent> <buffer> <Tab> :call <SID>TodoListsIncreaseIndent()<CR>
    vnoremap <silent> <buffer> <S-Tab> :call <SID>TodoListsDecreaseIndent()<CR>
    inoremap <silent> <buffer> <Tab> <ESC>:call <SID>TodoListsIncreaseIndent()<CR>A
    inoremap <silent> <buffer> <S-Tab> <ESC>:call <SID>TodoListsDecreaseIndent()<CR>A

    nnoremap <silent> <buffer> [[ :call <SID>TodoListsGoToPreviousBaseItem()<CR>
    nnoremap <silent> <buffer> ]] :call <SID>TodoListsGoToNextBaseItem()<CR>
endfunction

" Creates a new item above the current line
function! s:TodoListsCreateNewItemAbove()
    normal! O- [ ] 
    startinsert!
endfunction


" Creates a new item below the current line
function! s:TodoListsCreateNewItemBelow()
    normal! o- [ ] 
    startinsert!
endfunction

" Creates a new item in the current line
function! s:TodoListsCreateNewItem()
    " If prev line is empty item, delete it
    if getline(line('.')-1) =~ '^\s*- \[[ X ]\]\s*$'
        call setline(line('.')-1, '')
        call s:TodoListsUpdateParent(line('.')-2)
    endif

    normal! 0i- [ ] 
    let l:prev_line = getline(line('.')-1)
    if s:TodoListsLineIsItem(l:prev_line)
        let l:indent = indent(line('.')-1)
        if l:indent > 0
            execute "normal! " . l:indent . "I "
        endif
    endif
    startinsert!
endfunction


" Moves the cursor to the next item
function! s:TodoListsGoToNextItem()
    normal! $
    silent! exec '/^\s*- \[.\]'
    silent! exec 'noh'
    normal! l
endfunction


" Moves the cursor to the previous item
function! s:TodoListsGoToPreviousItem()
    normal! 0
    silent! exec '?^\s*- \[.\]'
    silent! exec 'noh'
    normal! l
endfunction


" Moves the cursor to the next base item
function! s:TodoListsGoToNextBaseItem()
    normal! $
    silent! exec '/^- \[.\]'
    silent! exec 'noh'
    normal! l
endfunction


" Moves the cursor to the previous base item
function! s:TodoListsGoToPreviousBaseItem()
    normal! 0
    silent! exec '?^- \[.\]'
    silent! exec 'noh'
    normal! l
endfunction


" Toggles todo list item
function! s:TodoListsToggleItem()
    let l:line = getline('.')
    let l:lineno = line('.')

    " Store current cursor position
    let l:cursor_pos = getcurpos()

    if s:TodoListsItemIsNotDone(l:line) == 1
        call s:TodoListsForEachChild(l:lineno, 's:TodoListsSetItemDone')
    elseif s:TodoListsItemIsDone(l:line) == 1
        call s:TodoListsForEachChild(l:lineno, 's:TodoListsSetItemNotDone')
    endif

    call s:TodoListsUpdateParent(l:lineno)

    " Restore the current position
    " Using the {curswant} value to set the proper column
    call cursor(l:cursor_pos[1], l:cursor_pos[4])
endfunction

function! s:TodoListsDeleteItem(lineno)
    let l:indent = s:TodoListsCountLeadingSpaces(getline(a:lineno))
    execute "normal! :" . a:lineno . "," . s:TodoListsFindLastChild(a:lineno) . "d\<CR>"
    if l:indent == 0 && getline(a:lineno) == ''
        normal! dd
    endif
endfunction

function! s:TodoListsCleanItemsDone()
    let l:lineno = 0
    while l:lineno < line('$')
        let l:line = getline(l:lineno)
        if s:TodoListsLineIsItem(l:line) && s:TodoListsItemIsDone(l:line)
            call s:TodoListsDeleteItem(l:lineno)
        else
            let l:lineno += 1
        endif
    endwhile
endfunction

" Increases the indent level
function! s:TodoListsIncreaseIndent()
    normal! >>
endfunction

" Decreases the indent level
function! s:TodoListsDecreaseIndent()
    normal! <<
endfunction


setlocal tabstop=2
setlocal shiftwidth=2 expandtab
setlocal cursorline
setlocal noautoindent

function s:TodoListsDisableUndo()
    let s:disable_undo = 1
endfunction

function s:TodoListsEnableUndo()
    let s:disable_undo = 0
endfunction

function s:TodoListsUndo()
    call s:TodoListsDisableUndo()
    normal! u
endfunction

function s:TodoListsRedo()
    call s:TodoListsDisableUndo()
    normal! 
endfunction

let s:disable_undo = 0
nnoremap <silent><buffer> u :call <SID>TodoListsUndo()<CR>:call <SID>TodoListsEnableUndo()<CR>
nnoremap <silent><buffer> <C-R> :call <SID>TodoListsRedo()<CR>:call <SID>TodoListsEnableUndo()<CR>

if exists('g:TodoListsCustomKeyMapper')
    try
        call call(g:TodoListsCustomKeyMapper, [])
    catch
        echo 'TodoLists: Error in custom key mapper. Falling back to default mappings'
        call s:TodoListsSetItemMode()
    endtry
else
    call s:TodoListsSetItemMode()
endif

augroup Todo
    autocmd!

    autocmd TextChanged * call s:TodoListsUpdateItems(line('.'))
    autocmd InsertEnter * call s:TodoListsUpdateItems(line('.'))
augroup END

