" MIT License
"
" Copyright (c) 2019 Alexander Serebryakov (alex.serebr@gmail.com)
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to
" deal in the Software without restriction, including without limitation the
" rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
" sell copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
" FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
" IN THE SOFTWARE.


" Initializes plugin settings and mappings
function! s:VimTodoListsInit()
  set filetype=todo

  if !exists('g:VimTodoListsDatesEnabled')
    let g:VimTodoListsDatesEnabled = 0
  endif

  if !exists('g:VimTodoListsDatesFormat')
    let g:VimTodoListsDatesFormat = "%X, %d %b %Y"
  endif

  setlocal tabstop=2
  setlocal shiftwidth=2 expandtab
  setlocal cursorline
  setlocal noautoindent

  if exists('g:VimTodoListsCustomKeyMapper')
    try
      call call(g:VimTodoListsCustomKeyMapper, [])
    catch
      echo 'VimTodoLists: Error in custom key mapper.'
           \.' Falling back to default mappings'
      call s:VimTodoListsSetItemMode()
    endtry
  else
    call s:VimTodoListsSetItemMode()
  endif

  call s:VimTodoListsMigrate()

endfunction


" Sets the item done
function! s:VimTodoListsSetItemDone(lineno)
  let l:line = getline(a:lineno)
  call setline(a:lineno, substitute(l:line, '^\(\s*- \)\[ \]', '\1[X]', ''))
endfunction


" Sets the item not done
function! s:VimTodoListsSetItemNotDone(lineno)
  let l:line = getline(a:lineno)
  call setline(a:lineno, substitute(l:line, '^\(\s*- \)\[X\]', '\1[ ]', ''))
endfunction


" Checks that line is a todo list item
function! s:VimTodoListsLineIsItem(line)
  if match(a:line, '^\s*- \[[ X]\].*') != -1
    return 1
  endif

  return 0
endfunction


" Checks that item is not done
function! s:VimTodoListsItemIsNotDone(line)
  if match(a:line, '^\s*- \[ \].*') != -1
    return 1
  endif

  return 0
endfunction


" Checks that item is done
function! s:VimTodoListsItemIsDone(line)
  if match(a:line, '^\s*- \[X\].*') != -1
    return 1
  endif

  return 0
endfunction


" Returns the line number of the brother item in specified range
function! s:VimTodoListsBrotherItemInRange(line, range)
  let l:indent = s:VimTodoListsCountLeadingSpaces(getline(a:line))
  let l:result = -1

  for current_line in a:range
    if s:VimTodoListsLineIsItem(getline(current_line)) == 0
      break
    endif

    if (s:VimTodoListsCountLeadingSpaces(getline(current_line)) == l:indent)
      let l:result = current_line
      break
    elseif (s:VimTodoListsCountLeadingSpaces(getline(current_line)) > l:indent)
      continue
    else
      break
    endif
  endfor

  return l:result
endfunction


" Finds the insert position above the item
function! s:VimTodoListsFindTargetPositionUp(lineno)
  let l:range = range(a:lineno, 1, -1)
  let l:candidate_line = s:VimTodoListsBrotherItemInRange(a:lineno, l:range)
  let l:target_line = -1

  while l:candidate_line != -1
    let l:target_line = l:candidate_line
    let l:candidate_line = s:VimTodoListsBrotherItemInRange(
      \ l:candidate_line, range(l:candidate_line - 1, 1, -1))

    if l:candidate_line != -1 &&
      \ s:VimTodoListsItemIsNotDone(getline(l:candidate_line)) == 1
      let l:target_line = l:candidate_line
      break
    endif
  endwhile

  return s:VimTodoListsFindLastChild(l:target_line)
endfunction


" Finds the insert position below the item
function! s:VimTodoListsFindTargetPositionDown(line)
  let l:range = range(a:line, line('$'))
  let l:candidate_line = s:VimTodoListsBrotherItemInRange(a:line, l:range)
  let l:target_line = -1

  while l:candidate_line != -1
    let l:target_line = l:candidate_line
    let l:candidate_line = s:VimTodoListsBrotherItemInRange(
      \ l:candidate_line, range(l:candidate_line + 1, line('$')))
  endwhile

  return s:VimTodoListsFindLastChild(l:target_line)
endfunction


" Moves the item subtree to the specified position
function! s:VimTodoListsMoveSubtree(lineno, position)
  if exists('g:VimTodoListsMoveItems')
    if g:VimTodoListsMoveItems != 1
      return
    endif
  endif

  let l:subtree_length = s:VimTodoListsFindLastChild(a:lineno) - a:lineno + 1

  let l:cursor_pos = getcurpos()
  call cursor(a:lineno, l:cursor_pos[4])

  " Update cursor position
  let l:cursor_pos[1] = a:lineno

  " Copy subtree to the required position
  execute 'normal! ' . l:subtree_length . 'Y'
  call cursor(a:position, l:cursor_pos[4])

  if a:lineno < a:position
    execute 'normal! p'
    " In case of moving item down cursor should be returned to exact position
    " where it was before
    call cursor(l:cursor_pos[1], l:cursor_pos[4])
  else
    let l:indent = s:VimTodoListsCountLeadingSpaces(getline(a:lineno))

    if s:VimTodoListsItemIsDone(getline(a:position)) &&
       \ (s:VimTodoListsCountLeadingSpaces(getline(a:position)) == l:indent)
      execute 'normal! P'
    else
      execute 'normal! p'
    endif

    " In case of moving item up the text became one longer by a subtree length
    call cursor(l:cursor_pos[1] + l:subtree_length, l:cursor_pos[4])
  endif

  " Delete subtree in the initial position
  execute 'normal! ' . l:subtree_length . 'dd'

endfunction


" Moves the subtree up
function! s:VimTodoListsMoveSubtreeUp(lineno)
  let l:move_position = s:VimTodoListsFindTargetPositionUp(a:lineno)

  if l:move_position != -1
    call s:VimTodoListsMoveSubtree(a:lineno, l:move_position)
  endif
endfunction


" Moves the subtree down
function! s:VimTodoListsMoveSubtreeDown(lineno)
  let l:move_position = s:VimTodoListsFindTargetPositionDown(a:lineno)

  if l:move_position != -1
    call s:VimTodoListsMoveSubtree(a:lineno, l:move_position)
  endif
endfunction


" Counts the number of leading spaces
function! s:VimTodoListsCountLeadingSpaces(line)
  return (strlen(a:line) - strlen(substitute(a:line, '^\s*', '', '')))
endfunction


" Returns the line number of the parent
function! s:VimTodoListsFindParent(lineno)
  let l:indent = s:VimTodoListsCountLeadingSpaces(getline(a:lineno))
  let l:parent_lineno = -1

  for current_line in range(a:lineno, 1, -1)
    if (s:VimTodoListsLineIsItem(getline(current_line)) &&
      \ s:VimTodoListsCountLeadingSpaces(getline(current_line)) < l:indent)
      let l:parent_lineno = current_line
      break
    endif
  endfor

  return l:parent_lineno
endfunction


" Returns the line number of the last child
function! s:VimTodoListsFindLastChild(lineno)
  let l:indent = s:VimTodoListsCountLeadingSpaces(getline(a:lineno))
  let l:last_child_lineno = a:lineno

  " If item is the last line in the buffer it has no children
  if a:lineno == line('$')
    return l:last_child_lineno
  endif

  for current_line in range (a:lineno + 1, line('$'))
    if (s:VimTodoListsLineIsItem(getline(current_line)) &&
      \ s:VimTodoListsCountLeadingSpaces(getline(current_line)) > l:indent)
      let l:last_child_lineno = current_line
    else
      break
    endif
  endfor

  return l:last_child_lineno
endfunction


" Marks the parent done if all children are done
function! s:VimTodoListsUpdateParent(lineno)
  let l:parent_lineno = s:VimTodoListsFindParent(a:lineno)

  " No parent item
  if l:parent_lineno == -1
    return
  endif

  let l:last_child_lineno = s:VimTodoListsFindLastChild(l:parent_lineno)

  " There is no children
  if l:last_child_lineno == l:parent_lineno
    return
  endif

  for current_line in range(l:parent_lineno + 1, l:last_child_lineno)
    if s:VimTodoListsItemIsNotDone(getline(current_line)) == 1
      " Not all children are done
      call s:VimTodoListsSetItemNotDone(l:parent_lineno)
      call s:VimTodoListsMoveSubtreeUp(l:parent_lineno)
      call s:VimTodoListsUpdateParent(l:parent_lineno)
      return
    endif
  endfor

  call s:VimTodoListsSetItemDone(l:parent_lineno)
  call s:VimTodoListsMoveSubtreeDown(l:parent_lineno)
  call s:VimTodoListsUpdateParent(l:parent_lineno)
endfunction


" Applies the function for each child
function! s:VimTodoListsForEachChild(lineno, function)
  let l:last_child_lineno = s:VimTodoListsFindLastChild(a:lineno)

  " Apply the function on children prior to the item.
  " This order is required for proper work of the items moving on toggle
  for current_line in range(a:lineno, l:last_child_lineno)
    call call(a:function, [current_line])
  endfor
endfunction


" Sets mapping for normal navigation and editing mode
function! s:VimTodoListsSetNormalMode()
  nunmap <buffer> o
  nunmap <buffer> O
  nunmap <buffer> j
  nunmap <buffer> k
  nnoremap <silent> <buffer> <Space> :call <SID>VimTodoListsToggleItem()<CR>
  vnoremap <silent> <buffer> <Space> :'<,'>call <SID>VimTodoListsToggleItem()<CR>
  noremap  <silent> <buffer> <leader>e :call <SID>VimTodoListsSetItemMode()<CR>
endfunction


" Sets mappings for faster item navigation and editing
function! s:VimTodoListsSetItemMode()
  nnoremap <silent> <buffer> o :call <SID>VimTodoListsCreateNewItemBelow()<CR>
  nnoremap <silent> <buffer> O :call <SID>VimTodoListsCreateNewItemAbove()<CR>
  nnoremap <silent> <buffer> j :call <SID>VimTodoListsGoToNextItem()<CR>
  nnoremap <silent> <buffer> k :call <SID>VimTodoListsGoToPreviousItem()<CR>
  nnoremap <silent> <buffer> <Space> :call <SID>VimTodoListsToggleItem()<CR>
  vnoremap <silent> <buffer> <Space> :call <SID>VimTodoListsToggleItem()<CR>
  inoremap <silent> <buffer> <CR> <ESC>:call <SID>VimTodoListsAppendDate()<CR>A<CR><ESC>:call <SID>VimTodoListsCreateNewItem()<CR>
  noremap  <silent> <buffer> <leader>e :silent call <SID>VimTodoListsSetNormalMode()<CR>
  nnoremap <silent> <buffer> <Tab> :call <SID>VimTodoListsIncreaseIndent()<CR>
  nnoremap <silent> <buffer> <S-Tab> :call <SID>VimTodoListsDecreaseIndent()<CR>
  vnoremap <silent> <buffer> <Tab> :call <SID>VimTodoListsIncreaseIndent()<CR>
  vnoremap <silent> <buffer> <S-Tab> :call <SID>VimTodoListsDecreaseIndent()<CR>
  inoremap <silent> <buffer> <Tab> <ESC>:call <SID>VimTodoListsIncreaseIndent()<CR>A
  inoremap <silent> <buffer> <S-Tab> <ESC>:call <SID>VimTodoListsDecreaseIndent()<CR>A
endfunction

" Appends date at the end of the line
function! s:VimTodoListsAppendDate()
  if(g:VimTodoListsDatesEnabled == 1)
    let l:date = strftime(g:VimTodoListsDatesFormat)
    execute "s/$/ (" . l:date . ")"
  endif
endfunction

" Creates a new item above the current line
function! s:VimTodoListsCreateNewItemAbove()
  normal! O- [ ] 
  startinsert!
endfunction


" Creates a new item below the current line
function! s:VimTodoListsCreateNewItemBelow()
  normal! o- [ ] 
  startinsert!
endfunction

" Creates a new item in the current line
function! s:VimTodoListsCreateNewItem()
  normal! 0i- [ ] 
  startinsert!
endfunction


" Moves the cursor to the next item
function! s:VimTodoListsGoToNextItem()
  normal! $
  silent! exec '/^\s*- \[.\]'
  silent! exec 'noh'
  normal! l
endfunction


" Moves the cursor to the previous item
function! s:VimTodoListsGoToPreviousItem()
  normal! 0
  silent! exec '?^\s*- \[.\]'
  silent! exec 'noh'
  normal! l
endfunction


" Toggles todo list item
function! s:VimTodoListsToggleItem()
  let l:line = getline('.')
  let l:lineno = line('.')

  " Store current cursor position
  let l:cursor_pos = getcurpos()

  if s:VimTodoListsItemIsNotDone(l:line) == 1
    call s:VimTodoListsForEachChild(l:lineno, 's:VimTodoListsSetItemDone')
    call s:VimTodoListsMoveSubtreeDown(l:lineno)
  elseif s:VimTodoListsItemIsDone(l:line) == 1
    call s:VimTodoListsForEachChild(l:lineno, 's:VimTodoListsSetItemNotDone')
    call s:VimTodoListsMoveSubtreeUp(l:lineno)
  endif

  call s:VimTodoListsUpdateParent(l:lineno)

  " Restore the current position
  " Using the {curswant} value to set the proper column
  call cursor(l:cursor_pos[1], l:cursor_pos[4])
endfunction

" Increases the indent level
function! s:VimTodoListsIncreaseIndent()
  normal! >>
endfunction

" Decreases the indent level
function! s:VimTodoListsDecreaseIndent()
  normal! <<
endfunction

" Migrates file to new format
function! s:VimTodoListsMigrate()
  normal! mz
  silent! execute ':%s/^\(\s*\)\(\[.\]\)/\1- \2/'
  normal! 'z
endfunction

"Plugin startup code
if !exists('g:vimtodolists_plugin')
  let g:vimtodolists_plugin = 1

  if exists('vimtodolists_auto_commands')
    echoerr 'VimTodoLists: vimtodolists_auto_commands group already exists'
    exit
  endif

  "Defining auto commands
  augroup vimtodolists_auto_commands
    autocmd!
    autocmd BufRead,BufNewFile *.todo call s:VimTodoListsInit()
    autocmd BufRead,BufNewFile ToDo call s:VimTodoListsInit()
  augroup end
endif

