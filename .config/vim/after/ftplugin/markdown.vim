scriptencoding utf-8

" after/ftplugin/markdown.vim  –  local patches on top of vim-markdown
"
" Load order (per-buffer, each ftplugin event):
"   1. <plugin>/ftplugin/markdown.vim      (remote vim-markdown)
"   2. <plugin>/after/ftplugin/markdown.vim (remote vim-markdown)
"   3. THIS FILE                            (patch-vim-markdown)

let s:orig_script_info = getscriptinfo({"name": "vim-markdown/ftplugin/markdown.vim"})
if empty(s:orig_script_info) | finish | endif
let s:orig_script_id = string(s:orig_script_info[0]["sid"])

function! s:GetOrigPluginFn(fn_name)
    return function("<SNR>" . s:orig_script_id . "_" . a:fn_name)
endfunction


" ============================================================
" 1.  Remove remote-plugin autocmds that conflict with our
"     mode-based fold / syntax-refresh setup.
" ============================================================
augroup Mkd
    autocmd! * <buffer>
augroup END

function! s:MapKey(lhs, rhs)
    execute "nmap <buffer><silent> " . a:lhs . " " . a:rhs
    execute "omap <buffer><silent> " . a:lhs . " " . a:rhs
    execute "vmap <buffer><silent> " . a:lhs . " " . a:rhs
endfunction

function! s:VisMove(f)
    normal! gv
    call function(a:f)()
endfunction

function! s:MapNormVis(lhs, rhs)
    execute 'nnoremap <buffer><silent> ' . a:lhs . ' <Cmd>call' . a:rhs . '()<CR>'
    execute 'vnoremap <buffer><silent> ' . a:lhs . ' <Cmd>call <SID>VisMove(''' . a:rhs . ''')<CR>'
endfunction

function! s:Toc(...)
    let l:filename = expand('%:t')

    let l:save_spr = &splitright
    set nosplitright
    call call(s:GetOrigPluginFn("Toc"), a:000)
    let &splitright=l:save_spr

    let b:toc_filename = l:filename
    setlocal filetype=toc
    setlocal foldlevel=99
    setlocal foldmethod=indent
    .ll
    execute "normal! zvjzvzczOkzt\<C-W>p"
endfunction

" ============================================================
" 2.  Bullet / indent manipulation
" ============================================================

function! s:Markdown_ShouldIndent()
    let l:line  = getline('.')
    let l:is_bullet    = '^\s*[-+*.|]\%( \[.\]\)\?\s*.*$'
    let l:no_text_yet  = '^\s*[-+*.|]\%( \[.\]\)\?\s*$'
    let l:beginning    = l:line[:col('.') - 1]
    let l:is_not_letters = '^\s*\%(\|[-+*.|]\%(\| \[.\]\)\)\?$'
    return l:line =~ l:is_bullet &&
        \ (l:line =~ l:no_text_yet || l:beginning =~ l:is_not_letters)
endfunction

function! s:Markdown_ModifyBullet(direction, ...)
    let l:line_nb = (a:0 > 0 ? a:1 : line('.'))
    let l:line    = getline(l:line_nb)
    let l:bullets = ['-', '+', '*', '.', '|']
    let l:regex   = '^\s*\([-+*.|]\)\%(\s\+.*\)\?$'
    let l:match   = matchlist(l:line, l:regex)
    if empty(l:match) | return | endif

    let l:bullet = l:match[1]
    let l:index  = index(l:bullets, l:bullet) + a:direction

    " Don't modify bullet if on first column and going left
    if a:direction == -1 && stridx(l:line, l:bullet) == 0 | return | endif

    let l:bullet     = (l:bullet ==# '.' ? '\V.' : l:bullet)
    let l:new_bullet = l:bullets[l:index % len(l:bullets)]
    call setline(l:line_nb, substitute(l:line, l:bullet, l:new_bullet, ""))
endfunction

function! s:Markdown_RemoveBullet()
    if getline('.') =~ '^\s*[-+*.|]\s*$'
        let l:line_to_bullet = matchlist(getline('.'), '^\(\s*[-+*.|]\).*$')[1]
        let l:len_line       = len(l:line_to_bullet)
        if getline(line('.') + 1)[:l:len_line - 1] !=# l:line_to_bullet
            normal! 0D
        else
            execute "normal! a\<Space>"
        endif
    endif
endfunction

function! s:Markdown_Indent()
    call s:Markdown_ModifyBullet(1)
    normal! >>f]2l
    call s:TodoList_UpdateParents(-1, 0)
    call repeat#set("\<Plug>Markdown_Indent", -1)
endfunction

function! s:Markdown_Dedent()
    call s:Markdown_ModifyBullet(-1)
    normal! <<f]2l
    call s:TodoList_UpdateParents(-1, 0)
    call repeat#set("\<Plug>Markdown_Dedent", -1)
endfunction

function! s:Markdown_ModifyIndentRange(type)
    if a:type ==? 'line'
        let l:min_line = line("'[")
        let l:max_line = line("']")
    else
        let l:min_line = line("'<")
        let l:max_line = line("'>")
    endif
    for l:lnum in range(l:max_line, l:min_line, -1)
        call s:Markdown_ModifyBullet(1, l:lnum)
        execute l:lnum . "normal! >>"
    endfor
    call s:TodoList_UpdateParent(l:max_line)
endfunction

function! s:Markdown_ModifyDedentRange(type)
    if a:type ==? 'line'
        let l:min_line = line("'[")
        let l:max_line = line("']")
    else
        let l:min_line = line("'<")
        let l:max_line = line("'>")
    endif
    for l:lnum in range(l:max_line, l:min_line, -1)
        call s:Markdown_ModifyBullet(-1, l:lnum)
        execute l:lnum . "normal! <<"
    endfor
    call s:TodoList_UpdateParent(l:min_line - 1)
endfunction

" ============================================================
" 3.  TodoList functions
" ============================================================

function! s:TodoList_SetItemDone(lineno)
    let l:line = getline(a:lineno)
    call setline(a:lineno, substitute(l:line,
        \ '^\(\s*\%([-+*.|]\|\d\+\.\) \)\[[^X]\]', '\1[X]', ''))
endfunction

function! s:TodoList_SetItemNotDone(lineno)
    let l:line = getline(a:lineno)
    call setline(a:lineno, substitute(l:line,
        \ '^\(\s*\%([-+*.|]\|\d\+\.\) \)\[[-X]\]', '\1[ ]', ''))
endfunction

function! s:TodoList_SetItemInProg(lineno)
    let l:line = getline(a:lineno)
    call setline(a:lineno, substitute(l:line,
        \ '^\(\s*\%([-+*.|]\|\d\+\.\) \)\[[^X]\]', '\1[-]', ''))
endfunction

function! s:TodoList_LineIsItem(line)
    return a:line =~ '^\s*\%([-+*.|]\|\d\+\.\) \[.\].*'
endfunction

function! s:TodoList_ItemIsNotDone(line)
    return a:line =~ '^\s*\%([-+*.|]\|\d\+\.\) \[[^X]\].*'
endfunction

function! s:TodoList_ItemIsDone(line)
    return a:line =~ '^\s*\%([-+*.|]\|\d\+\.\) \[X\].*'
endfunction

function! s:TodoList_FindParent(lineno)
    let l:indent = indent(a:lineno)
    if l:indent == 0 | return -1 | endif
    for current_line in range(a:lineno, 1, -1)
        if s:TodoList_LineIsItem(getline(current_line)) && indent(current_line) < l:indent
            return current_line
        endif
    endfor
    return -1
endfunction

function! s:TodoList_FindLastChild(lineno)
    if a:lineno == line('$') | return a:lineno | endif
    let l:indent            = indent(a:lineno)
    let l:last_child_lineno = a:lineno
    for current_line in range(a:lineno + 1, line('$'))
        if s:TodoList_LineIsItem(getline(current_line)) && indent(current_line) > l:indent
            let l:last_child_lineno = current_line
        else
            break
        endif
    endfor
    return l:last_child_lineno
endfunction

function! s:TodoList_UpdateParent(lineno)
    let l:parent_lineno = s:TodoList_FindParent(a:lineno)
    if l:parent_lineno == -1 | return | endif

    let l:last_child_lineno = s:TodoList_FindLastChild(l:parent_lineno)
    if l:last_child_lineno == l:parent_lineno | return | endif

    " If (parent done && one child not done) || (parent not done && all child done), update
    let l:parent_done = s:TodoList_ItemIsDone(getline(l:parent_lineno))
    for current_line in range(l:parent_lineno + 1, l:last_child_lineno)
        if s:TodoList_ItemIsNotDone(getline(current_line))
            if l:parent_done
                call s:TodoList_SetItemNotDone(l:parent_lineno)
                call s:TodoList_UpdateParent(l:parent_lineno)
            endif
            return
        endif
    endfor

    call s:TodoList_SetItemDone(l:parent_lineno)
    call s:TodoList_UpdateParent(l:parent_lineno)
endfunction

function! s:TodoList_UpdateParents(...)
    for line in a:000
        call s:TodoList_UpdateParent(line('.') + line)
    endfor
endfunction

function! s:TodoList_ForEachChild(lineno, function)
    let l:last_child_lineno = s:TodoList_FindLastChild(a:lineno)

    " Apply the function on children prior to the item.
    " This order is required for proper work of the items moving on toggle
    for current_line in range(a:lineno, l:last_child_lineno)
        call call(a:function, [current_line])
    endfor
endfunction

function! s:TodoList_CreateNewItemAbove()
    normal! O
    call s:TodoList_CreateNewItem(line('.'))
    startinsert!
endfunction

function! s:TodoList_CreateNewItemBelow()
    normal! o
    call s:TodoList_CreateNewItem(line('.') - 1)
    startinsert!
endfunction

function! s:TodoList_CreateNewItem(update_line)
    " If previous line is an empty item, blank it out
    if getline(line('.') - 1) =~ '^\s*\%([-+*.|]\|\d\+\.\) \[[ X ]\]\s*$'
        call setline(line('.') - 1, '')
        call s:TodoList_UpdateParent(line('.') - 2)
    endif

    let l:prev_nb = line('.') - 1
    while l:prev_nb > 0 && getline(l:prev_nb) =~ '^\s*$'
        let l:prev_nb -= 1
    endwhile

    let l:prev = getline(l:prev_nb)
    if l:prev =~ '^\s*\d\+\. \[[X ]\] '
        let l:beg_ind  = match(l:prev, '\d')
        let l:end_ind  = match(l:prev, '\.')
        let l:bullet_nb = str2nr(l:prev[l:beg_ind : l:end_ind - 1]) + 1
        let l:indent    = l:beg_ind > 0 ? l:prev[:l:beg_ind - 1] : ''
        call setline(line('.'), l:indent . l:bullet_nb . ". [ ] " . getline('.'))
        startinsert!
        return
    endif

    " If previous line is an item, copy its bullet type and indentation by
    " copying the beginning of the line
    let l:prev_line = getline(line('.') - 1)
    if s:TodoList_LineIsItem(l:prev_line)
        let l:end_index = match(l:prev_line, '\] ')
        call setline(line('.'), l:prev_line[:l:end_index + 1] . getline('.'))
        call s:TodoList_SetItemNotDone(line('.'))

        " If prev line now ends with a space, remove it
        if l:prev_line[-1:] ==# ' ' | call setline(line('.') - 1, l:prev_line[:-2]) | endif
    else
        call setline(line('.'), '- [ ] ' . getline('.'))
    endif

    call s:TodoList_UpdateParent(a:update_line)
    startinsert!
endfunction

function! s:TodoList_GoToNextItem(count)
    let l:saved_shortmess = &shortmess
    set shortmess+=s
    normal! $
    silent! exec '/^\s*\%([-+*.|]\|\d\+\.\) \[.\]\|\v^(#|.+\n(\=+|-+)$)'
    for i in range(a:count - 1)
        keepjumps normal! nw
    endfor
    silent! exec 'noh'
    normal! f]2l
    let &shortmess = l:saved_shortmess
endfunction

function! s:TodoList_GoToPreviousItem(count)
    let l:saved_shortmess = &shortmess
    set shortmess+=s
    normal! 0
    silent! exec '?^\s*\%([-+*.|]\|\d\+\.\) \[.\]\|\v^(#|.+\n(\=+|-+)$)'
    for i in range(a:count - 1)
        keepjumps normal! 0nw
    endfor
    silent! exec 'noh'
    normal! f]2l
    let &shortmess = l:saved_shortmess
endfunction

function! s:TodoList_GoToNextBaseItem()
    normal! $
    silent! exec '/^\%([-+*.|]\|\d\+\.\) \[.\]'
    silent! exec 'noh'
    normal! l
endfunction

function! s:TodoList_GoToPreviousBaseItem()
    normal! 0
    silent! exec '?^\%([-+*.|]\|\d\+\.\) \[.\]'
    silent! exec 'noh'
    normal! l
endfunction

function! s:TodoList_GetLineItem(line)
    let l:item_line = a:line
    while l:item_line > -1 && !s:TodoList_LineIsItem(getline(l:item_line))
        let l:item_line -= 1
    endwhile
    return l:item_line
endfunction

function! s:TodoList_GoToNextSiblingItem()
    let l:curr_item_line = s:TodoList_GetLineItem(line('.'))
    if l:curr_item_line < 0 | echo 'No next sibling item' | return | endif

    let l:indent           = indent(l:curr_item_line)
    let l:next_sibling_line = line('.') + 1
    while l:next_sibling_line < line('$') &&
            \ (!s:TodoList_LineIsItem(getline(l:next_sibling_line)) ||
            \  indent(l:next_sibling_line) > l:indent)
        let l:next_sibling_line += 1
    endwhile

    if indent(l:next_sibling_line) == l:indent
        call cursor(l:next_sibling_line, 1)
        normal! ^
    else
        echo 'No next sibling item'
    endif
endfunction

function! s:TodoList_GoToPreviousSiblingItem()
    let l:curr_item_line = s:TodoList_GetLineItem(line('.'))
    if l:curr_item_line < 0 | echo 'No prev sibling item' | return | endif

    let l:indent            = indent(l:curr_item_line)
    let l:prev_sibling_line = l:curr_item_line - 1
    while l:prev_sibling_line > -1 &&
            \ (!s:TodoList_LineIsItem(getline(l:prev_sibling_line)) ||
            \  indent(l:prev_sibling_line) > l:indent)
        let l:prev_sibling_line -= 1
    endwhile

    if indent(l:prev_sibling_line) == l:indent
        call cursor(l:prev_sibling_line, 1)
        normal! ^
    else
        echo 'No prev sibling item'
    endif
endfunction

function! s:TodoList_GoToParentItem()
    let l:curr_item_line = s:TodoList_GetLineItem(line('.'))
    let l:indent         = indent(l:curr_item_line)
    if l:curr_item_line < 0 || l:indent == 0 | echo 'No parent item' | return | endif

    let l:parent_line = l:curr_item_line - 1
    while l:parent_line > -1 &&
            \ (!s:TodoList_LineIsItem(getline(l:parent_line)) ||
            \  indent(l:parent_line) >= l:indent)
        let l:parent_line -= 1
    endwhile

    if l:parent_line > 0
        call cursor(l:parent_line, 1)
        normal! ^
    else
        echo 'No parent item'
    endif
endfunction

function! s:TodoList_GoToNextUndoneItem()
    call s:TodoList_GoToNextItem(1)
    while !s:TodoList_ItemIsNotDone(getline('.'))
        call s:TodoList_GoToNextItem(1)
    endwhile
endfunction

function! s:TodoList_GoToPrevUndoneItem()
    call s:TodoList_GoToPreviousItem(1)
    while !s:TodoList_ItemIsNotDone(getline('.'))
        call s:TodoList_GoToPreviousItem(1)
    endwhile
endfunction

function! s:TodoList_ToggleItem()
    let l:line       = getline('.')
    let l:lineno     = line('.')
    let l:cursor_pos = getcurpos()

    let l:is_not_done = s:TodoList_ItemIsNotDone(l:line)
    if l:is_not_done == 1
        call s:TodoList_ForEachChild(l:lineno, 's:TodoList_SetItemDone')
    elseif s:TodoList_ItemIsDone(l:line) == 1
        call s:TodoList_ForEachChild(l:lineno, 's:TodoList_SetItemNotDone')
    endif

    call s:TodoList_UpdateParent(l:lineno)
    call cursor(l:cursor_pos[1], l:cursor_pos[4])

    " Go to next item if we marked
    if l:is_not_done == 1
        call s:TodoList_GoToNextSiblingItem()
    endif
endfunction

function! s:TodoList_SetInProgItem()
    let l:line       = getline('.')
    let l:lineno     = line('.')
    let l:cursor_pos = getcurpos()

    if s:TodoList_ItemIsNotDone(l:line) == 1
        call s:TodoList_ForEachChild(l:lineno, 's:TodoList_SetItemInProg')
    endif

    call cursor(l:cursor_pos[1], l:cursor_pos[4])
endfunction

function! s:TodoList_DeleteItem(lineno, update)
    let l:indent = indent(a:lineno)
    execute "silent normal! :" . a:lineno . "," . s:TodoList_FindLastChild(a:lineno) . "d\<CR>"
    if line('.') < line('$') && l:indent == 0 && getline(a:lineno) ==# ''
        normal! "_dd
    endif
    if a:update
        call s:TodoList_UpdateParent(line('.') - (indent(line('.')) < l:indent))
    endif
endfunction

function! s:TodoList_CleanItemsDone()
    let l:lineno = 0
    while l:lineno <= line('$')
        let l:line = getline(l:lineno)
        if s:TodoList_LineIsItem(l:line) && s:TodoList_ItemIsDone(l:line)
            call s:TodoList_DeleteItem(l:lineno, 0)
        else
            let l:lineno += 1
        endif
    endwhile
endfunction

function! s:TodoList_MakeHeader()
    if getline('.') =~ '^\s*\%([-+*.|]\|\d\+\.\) \[.\]\s\+#\+ .*'
        normal! 0dt#$
    endif
endfunction

function! s:TodoList_JoinLine()
    if line('.') != line('$') && s:TodoList_LineIsItem(getline(line('.') + 1))
        normal! j0df]k
    endif
    normal! J
endfunction

function! s:TodoList_ShouldBS()
    return getline('.')[:col('.') - 2] =~ '^\s*\%([-+*.|]\|\d\+\.\) \[.\] \?$'
endfunction

function! s:TodoList_BackSpace()
    normal! 0df]
    if getline('.') ==# ' '
        normal! x
    elseif !s:TodoList_LineIsItem(getline(line('.') - 1))
        normal! xgP
    endif
endfunction

" ============================================================
" 4.  Fix Foldtext_markdown trailing space
"     (the remote omits it; add it only in pythonic mode where it's defined)
" ============================================================
if get(g:, 'vim_markdown_folding_style_pythonic', 0) && get(g:, 'vim_markdown_override_foldtext', 1)
    function! Foldtext_markdown()
        let line = getline(v:foldstart)
        let has_numbers = &number || &relativenumber
        let nucolwidth = &foldcolumn + has_numbers * &numberwidth
        let windowwidth = winwidth(0) - nucolwidth - 6
        let foldedlinecount = v:foldend - v:foldstart
        let line = strpart(line, 0, windowwidth - 2 - len(foldedlinecount))
        let line = substitute(line, '\%("""\|''''''\)', '', '')
        let fillcharcount = windowwidth - len(line) - len(foldedlinecount) + 1
        return line . ' ' . repeat('-', fillcharcount) . ' ' . foldedlinecount . ' '
    endfunction
endif


" ============================================================
" 5.  Set folding for Todo lists
" ============================================================

" - Non-item lines delegate to Foldexpr_markdown, preserving header folds.
" - Items WITH children open a fold: '>(base + indent/sw + 1)'.
" - Items WITHOUT children return 'base + indent/sw' (their parent's fold
"   level), so 'zc' closes the parent fold directly with no vacuous own fold.
" The base level is the enclosing markdown header level (0 if none).
function! Foldexpr_todolist(lnum)
    let l:line = getline(a:lnum)

    " Non-item lines: delegate to markdown folding (preserves header folds)
    if !s:TodoList_LineIsItem(l:line)
        return Foldexpr_markdown(a:lnum)
    endif

    let l:base   = s:GetOrigPluginFn("GetHeaderLevel")(a:lnum)
    let l:indent = indent(a:lnum)
    let l:sw     = shiftwidth()

    " Look ahead for a child item (greater indent), skipping blank lines
    let l:next = a:lnum + 1
    while l:next <= line('$')
        let l:next_line = getline(l:next)
        if s:TodoList_LineIsItem(l:next_line)
            if indent(l:next) > l:indent
                return '>' . (l:base + l:indent / l:sw + 1)
            endif
            break
        elseif l:next_line =~ '^\s*$'
            let l:next += 1
            continue
        else
            break
        endif
        let l:next += 1
    endwhile

    " No children: sit at the parent's fold level (no fold of its own)
    return l:base + l:indent / l:sw
endfunction

" Fold text for todo lists.
" - For item folds: show the item line + a count of actual child items.
" - For other folds (headers): delegate to the default fold text.
function! Foldtext_todolist()
    let l:line = getline(v:foldstart)
    if !s:TodoList_LineIsItem(l:line)
        return Foldtext_markdown()
    endif

    let l:n_children = 0
    for l:lnum in range(v:foldstart + 1, v:foldend)
        if s:TodoList_LineIsItem(getline(l:lnum))
            let l:n_children += 1
        endif
    endfor

    let l:suffix      = ' [' . l:n_children . (l:n_children > 1 ? ' items]' : ' item]')
    let l:has_numbers = &number || &relativenumber
    let l:nucolwidth  = &fdc + l:has_numbers * &numberwidth
    let l:windowwidth = winwidth(0) - l:nucolwidth - 6
    return strpart(l:line, 0, l:windowwidth - len(l:suffix)) . l:suffix
endfunction

" ============================================================
" 6.  Define TodoList Plug mappings
" ============================================================

call s:MapNormVis("<Plug>TodoList_GoToNextBaseItem", "<SID>TodoList_GoToNextBaseItem")
call s:MapNormVis("<Plug>TodoList_GoToPreviousBaseItem", "<SID>TodoList_GoToPreviousBaseItem")
call s:MapNormVis("<Plug>TodoList_GoToNextSiblingItem", "<SID>TodoList_GoToNextSiblingItem")
call s:MapNormVis("<Plug>TodoList_GoToPreviousSiblingItem", "<SID>TodoList_GoToPreviousSiblingItem")
call s:MapNormVis("<Plug>TodoList_GoToParentItem", "<SID>TodoList_GoToParentItem")
call s:MapNormVis("<Plug>TodoList_GoToPrevUndoneItem", "<SID>TodoList_GoToPrevUndoneItem")
call s:MapNormVis("<Plug>TodoList_GoToNextUndoneItem", "<SID>TodoList_GoToNextUndoneItem")

" ============================================================
" 7.  Mode setup
" ============================================================

function! s:SetCommonMappings()
    noremap  <buffer><silent> <leader>c :<C-U>Toc<CR>
    noremap  <buffer><silent>  <CR>  <Cmd>call <SID>TodoList_ToggleItem()<CR>
    noremap  <buffer><silent> g<CR>  <Cmd>call <SID>TodoList_SetInProgItem()<CR>

    nnoremap <buffer><silent> J      <Cmd>call <SID>TodoList_JoinLine()<CR>

    nmap <buffer><silent> gx <Plug>Markdown_OpenUrlUnderCursor
    nmap <buffer><silent> ge <Plug>Markdown_EditUrlUnderCursor

    " Indentation mappings
    nnoremap <buffer><silent> <Plug>Markdown_Indent <Cmd>call <SID>Markdown_Indent()<CR>
    nnoremap <buffer><silent> <Plug>Markdown_Dedent <Cmd>call <SID>Markdown_Dedent()<CR>
    nmap <buffer><silent> >> <Plug>Markdown_Indent
    nmap <buffer><silent> << <Plug>Markdown_Dedent

    nnoremap <buffer><silent> > :set opfunc=<SID>Markdown_ModifyIndentRange<CR>g@
    nnoremap <buffer><silent> < :set opfunc=<SID>Markdown_ModifyDedentRange<CR>g@
    vnoremap <buffer><silent> > <Cmd>call <SID>Markdown_ModifyIndentRange('visual')<CR>
    vnoremap <buffer><silent> < <Cmd>call <SID>Markdown_ModifyDedentRange('visual')<CR>

    inoremap <buffer><silent>       <C-T> <C-T><Cmd>call <SID>Markdown_ModifyBullet(1) \| call <SID>TodoList_UpdateParents(-1, 0)<CR>
    inoremap <buffer><silent><expr> <C-D> col('.')>strlen(getline('.')) ? "<Cmd>call <SID>Markdown_ModifyBullet(-1) \| call <SID>TodoList_UpdateParents(-1, 0)<CR><C-D>" : "<Del>"

    inoremap <buffer><silent><expr> <Tab>   <SID>Markdown_ShouldIndent() ? "<C-T><Cmd>call <SID>Markdown_ModifyBullet(1) \| call <SID>TodoList_UpdateParents(-1, 0)<CR>" : "<Tab>"
    inoremap <buffer><silent>       <S-Tab> <Cmd>call <SID>Markdown_ModifyBullet(-1) \| call <SID>TodoList_UpdateParents(-1, 0)<CR><C-D>
endfunction

" Sets mappings for normal navigation and editing mode
function! s:SetMarkdownMode()
    if exists('s:cursorline_backup') | let &cursorline = s:cursorline_backup | endif
    if exists('s:autoindent_backup') | let &autoindent = s:autoindent_backup | endif
    setlocal formatoptions-=c
    setlocal comments+=b:*,b:+,b:-,b:.,b:\|

    let b:todo_mode = 0

    if !get(g:, 'vim_markdown_folding_disabled', 0)
        if get(g:, 'vim_markdown_folding_style_pythonic', 0) && get(g:, 'vim_markdown_override_foldtext', 1)
            setlocal foldtext=Foldtext_markdown()
        else
            setlocal foldtext=
        endif
        setlocal foldexpr=Foldexpr_markdown(v:lnum)
        setlocal foldmethod=expr
    endif

    silent! nunmap <buffer> j
    silent! nunmap <buffer> k
    silent! nunmap <buffer> dd
    silent! nunmap <buffer> -
    silent! nunmap <buffer> _
    silent! nunmap <buffer> <leader>d
    silent! iunmap <buffer> <CR>
    silent! iunmap <buffer> <BS>
    silent! unmap  <buffer> <Tab>
    silent! unmap  <buffer> <S-Tab>
    silent! unmap  <buffer> ]]
    silent! unmap  <buffer> [[
    silent! unmap  <buffer> ][
    silent! unmap  <buffer> []
    silent! unmap  <buffer> ]u
    silent! unmap  <buffer> [i
    silent! unmap  <buffer> ]i
    silent! nunmap <buffer> u
    silent! nunmap <buffer> <C-R>
    silent! nunmap <buffer> <Tab>
    silent! nunmap <buffer> <S-Tab>

    call s:MapKey(']]', "<Plug>Markdown_MoveToNextHeader")
    call s:MapKey('[[', "<Plug>Markdown_MoveToPreviousHeader")
    call s:MapKey('][', "<Plug>Markdown_MoveToNextSiblingHeader")
    call s:MapKey('[]', "<Plug>Markdown_MoveToPreviousSiblingHeader")
    call s:MapKey(']u', "<Plug>Markdown_MoveToParentHeader")
    call s:MapKey(']y', "<Plug>Markdown_MoveToCurHeader")

    nnoremap <buffer><silent>        o A<CR>
    nnoremap <buffer><silent> <expr> O line('.') == 1 ? "O" : "kA<CR>"
    inoremap <buffer><silent> <CR>     <Cmd>call <SID>Markdown_RemoveBullet()<CR><CR>
    inoremap <buffer><silent> <BS>     <C-R>=autopairs#AutoPairsDelete()<CR>

    noremap  <buffer><silent> <leader>e :call <SID>SetTodoMode()<CR>
endfunction

" Sets mappings for faster item navigation and editing (todo mode)
function! s:SetTodoMode()
    let s:cursorline_backup = &cursorline
    let s:autoindent_backup = &autoindent
    setlocal cursorline
    setlocal noautoindent
    setlocal formatoptions+=c
    setlocal comments-=b:*,b:+,b:-,b:.,b:\|

    let b:todo_mode = 1

    setlocal foldmethod=expr
    setlocal foldexpr=Foldexpr_todolist(v:lnum)
    setlocal foldtext=Foldtext_todolist()
    setlocal foldlevel=99
    setlocal foldenable

    silent! unmap  <buffer> ]]
    silent! unmap  <buffer> [[
    silent! unmap  <buffer> ][
    silent! unmap  <buffer> []
    silent! unmap  <buffer> ]u
    silent! unmap  <buffer> ]y
    silent! iunmap <buffer> <CR>

    nnoremap <buffer><silent> o         <Cmd>call <SID>TodoList_CreateNewItemBelow()<CR>
    nnoremap <buffer><silent> O         <Cmd>call <SID>TodoList_CreateNewItemAbove()<CR>
    nnoremap <buffer><silent> j         <Cmd>call <SID>TodoList_GoToNextItem(v:count1)<CR>
    nnoremap <buffer><silent> k         <Cmd>call <SID>TodoList_GoToPreviousItem(v:count1)<CR>

    nnoremap <buffer><silent> dd        <Cmd>call <SID>TodoList_DeleteItem(line('.'), 1) \| call repeat#set("dd", -1)<CR>
    nnoremap <buffer><silent> <leader>d <Cmd>call <SID>TodoList_CleanItemsDone()<CR>

    nnoremap <buffer><silent> -         <Cmd>m .+1 \| call <SID>TodoList_UpdateParents(-1, 1, -2)<CR>
    nnoremap <buffer><silent> _         <Cmd>m .-2 \| call <SID>TodoList_UpdateParents(-1, 1, 2)<CR>

    inoremap <buffer><silent><expr> <BS>     <SID>TodoList_ShouldBS() ? "<Cmd>call <SID>TodoList_BackSpace()<CR><BS>" : "<C-R>=autopairs#AutoPairsDelete()<CR>"
    inoremap <buffer><silent>       <CR>     <C-O>:call <SID>TodoList_MakeHeader()<CR><CR><Cmd>call <SID>TodoList_CreateNewItem(line('.')-1)<CR>
    nmap     <buffer><silent>       <Tab>    <Plug>Markdown_Indent
    nmap     <buffer><silent>       <S-Tab>  <Plug>Markdown_Dedent

    call s:MapKey(']]', "<Plug>TodoList_GoToNextBaseItem")
    call s:MapKey('[[', "<Plug>TodoList_GoToPreviousBaseItem")
    call s:MapKey('][', "<Plug>TodoList_GoToNextSiblingItem")
    call s:MapKey('[]', "<Plug>TodoList_GoToPreviousSiblingItem")
    call s:MapKey(']u', "<Plug>TodoList_GoToParentItem")
    call s:MapKey('[i', "<Plug>TodoList_GoToPrevUndoneItem")
    call s:MapKey(']i', "<Plug>TodoList_GoToNextUndoneItem")

    noremap  <buffer><silent> <leader>e :silent call <SID>SetMarkdownMode()<CR>
endfunction

" ============================================================
" 8.  Override commands
" ============================================================

command! -buffer Toc  call s:Toc()
command! -buffer Toch call s:Toc('horizontal')
command! -buffer Tocv call s:Toc('vertical')
silent! delcommand -buffer Toct
silent! delcommand -buffer InsertToc
silent! delcommand -buffer InsertNToc

" ============================================================
" 9.  Buffer settings and initialisation
" ============================================================

setlocal conceallevel=2 concealcursor=c
setlocal shiftwidth=2 tabstop=2 expandtab

let b:AutoPairsMapCR = 0
let b:AutoPairsMapBS = 0

call s:SetCommonMappings()
if expand('%:t') =~# '.*\.todo' || expand('%:t') ==# 'ToDo'
    call s:SetTodoMode()
else
    call s:SetMarkdownMode()
endif

" vim: foldenable foldmethod=syntax
