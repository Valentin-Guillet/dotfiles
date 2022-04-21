" Script Variables {{{1

" For each level, contains the regexp that matches at that level only.
"
let s:levelRegexpDict = {
    \ 1: '\v^(#[^#]@=|.+\n\=+$)',
    \ 2: '\v^(##[^#]@=|.+\n-+$)',
    \ 3: '\v^###[^#]@=',
    \ 4: '\v^####[^#]@=',
    \ 5: '\v^#####[^#]@=',
    \ 6: '\v^######[^#]@='
\ }

" Maches any header level of any type.
"
" This could be deduced from `s:levelRegexpDict`, but it is more
" efficient to have a single regexp for this.
"
let s:headersRegexp = '\v^(#|.+\n(\=+|-+)$)'

" Markdown Functions {{{1

" Returns the line number of the first header before `line`, called the
" current header.
" If there is no current header, return `0`.
"
" @param a:1 The line to look the header of. Default value: `getpos('.')`.
function! s:GetHeaderLineNum(...)
    let l:line = (a:0 > 0 ? a:1 : line('.'))
    while l:line > 0
        if join(getline(l:line, l:line+1), "\n") =~ s:headersRegexp
            return l:line
        endif
        let l:line -= 1
    endwhile
    return 0
endfunction

" Returns the level of the header at the given line.
" If there is no header at the given line, returns `0`.
function! s:GetLevelOfHeaderAtLine(linenum)
    let l:lines = join(getline(a:linenum, a:linenum + 1), "\n")
    for l:key in keys(s:levelRegexpDict)
        if l:lines =~ get(s:levelRegexpDict, l:key)
            return l:key
        endif
    endfor
    return 0
endfunction

" If line is inside a header, return the header level (h1 -> 1, h2 -> 2, etc.).
" If line is at top level outside any headers, return `0`.
function! s:GetHeaderLevel(...)
    let l:line = (a:0 > 0 ? a:1 : line('.'))
    let l:linenum = s:GetHeaderLineNum(l:line)
    if l:linenum != 0
        return s:GetLevelOfHeaderAtLine(l:linenum)
    else
        return 0
    endif
endfunction

" If inside a header goes to it, returns its line number.
" If on top level outside any headers, print a warning and returns 0`.
function! s:Markdown_GoToCurrHeader(mode)
    if a:mode ==# 'v' | execute "normal! gv" | endif
    let l:lineNum = s:GetHeaderLineNum()
    if l:lineNum != 0
        call cursor(l:lineNum, 1)
    else
        echo 'Outside any header'
    endif
    return l:lineNum
endfunction

" Move cursor to next header of any level.
" If there are no more headers, print a warning.
function! s:Markdown_GoToNextHeader(mode)
    if a:mode ==# 'v' | execute "normal! gv" | endif
    if search(s:headersRegexp, 'W') == 0
        echo 'No next header'
    endif
endfunction

" Move cursor to previous header (before current) of any level.
" If it does not exist, print a warning.
function! s:Markdown_GoToPreviousHeader(mode)
    if a:mode ==# 'v' | execute "normal! gv" | endif
    let l:curHeaderLineNumber = s:GetHeaderLineNum()

    if l:curHeaderLineNumber <= 1 | echo 'No previous header' | return | endif

    let l:previousHeaderLineNumber = s:GetHeaderLineNum(l:curHeaderLineNumber - 1)
    if l:previousHeaderLineNumber == 0 | echo 'No previous header' | return | endif

    call cursor(l:previousHeaderLineNumber, 1)
endfunction

" Move cursor to parent header of the current header.
" If it does not exit, print a warning and do nothing.
function! s:Markdown_GoToParentHeader(mode)
    if a:mode ==# 'v' | execute "normal! gv" | endif
    let l:linenum = s:GetParentHeaderLineNumber()
    if l:linenum != 0
        call cursor(l:linenum, 1)
    else
        echo 'No parent header'
    endif
endfunction

" Return the line number of the parent header of line `line`.
" If it has no parent, return `0`.
function! s:GetParentHeaderLineNumber(...)
    let l:line = (a:0 > 0 ? a:1 : line('.'))
    let l:level = s:GetHeaderLevel(l:line)
    if l:level > 1
        let l:linenum = s:GetHeaderLineNumberAtLevel(l:level-1, -1, l:line)
        return l:linenum
    endif
    return 0
endfunction

" Return the line number of the next header of given level.
" in relation to line `a:1`. If not given, `a:1 = getline()`
" `a:1` line is included, and this may return the current header.
" If none return 0.
function! s:GetHeaderLineNumberAtLevel(level, direction, ...)
    let l:line = (a:0 > 0 ? a:1 : line('.'))
    while 0 < l:line && l:line <= line('$')
        if join(getline(l:line, l:line+1), "\n") =~ get(s:levelRegexpDict, a:level)
            return l:line
        endif
        let l:line += a:direction
    endwhile
    return 0
endfunction

" Move cursor to next sibling header.
" If there is no next siblings, print a warning and don't move.
function! s:Markdown_GoToSiblingHeader(direction, mode)
    if a:mode ==# 'v' | execute "normal! gv" | endif
    let l:curHeaderLineNumber = s:GetHeaderLineNum()
    let l:curHeaderLevel = s:GetLevelOfHeaderAtLine(l:curHeaderLineNumber)
    let l:curHeaderParentLineNumber = s:GetParentHeaderLineNumber()
    let l:nextHeaderSameLevelLineNumber = s:GetHeaderLineNumberAtLevel(l:curHeaderLevel, a:direction, l:curHeaderLineNumber+a:direction)

    let l:err_msg = "No " . (a:direction == 1 ? "next" : "previous") . " sibling header"
    if l:nextHeaderSameLevelLineNumber == 0 | echo l:err_msg | return | endif

    let l:nextHeaderSameLevelParentLineNumber = s:GetParentHeaderLineNumber(l:nextHeaderSameLevelLineNumber)
    if l:curHeaderParentLineNumber != l:nextHeaderSameLevelParentLineNumber | echo l:err_msg | return | endif

    call cursor(l:nextHeaderSameLevelLineNumber, 1)
endfunction

function! s:Markdown_GoToNextSiblingHeader(mode)
    call s:Markdown_GoToSiblingHeader(1, a:mode)
endfunction

function! s:Markdown_GoToPreviousSiblingHeader(mode)
    call s:Markdown_GoToSiblingHeader(-1, a:mode)
endfunction

function! s:Toc(...)
    let l:window_type = (a:0 > 0 ? a:1 : 'vertical')

    let l:filename = expand('%:t')
    let l:bufnr = bufnr('%')
    let l:cursor_line = line('.')
    let l:cursor_header = 0
    let l:fenced_block = 0
    let l:front_matter = 0
    let l:header_list = []
    let l:header_max_len = 0
    let l:vim_markdown_toc_autofit = get(g:, "vim_markdown_toc_autofit", 0)
    let l:vim_markdown_frontmatter = get(g:, "vim_markdown_frontmatter", 0)
    for i in range(1, line('$'))
        let l:lineraw = getline(i)
        let l:l1 = getline(i+1)
        let l:line = substitute(l:lineraw, "#", "\\\#", "g")
        if l:line =~ '````*' || l:line =~ '\~\~\~\~*'
            let l:fenced_block = (1 - l:fenced_block)
        elseif l:vim_markdown_frontmatter == 1
            if l:front_matter == 1
                if l:line == '---'
                    let l:front_matter = 0
                endif
            elseif i == 1
                if l:line == '---'
                    let l:front_matter = 1
                endif
            endif
        endif
        if l:line =~ '^#\+' || (l:l1 =~ '^=\+\s*$' || l:l1 =~ '^-\+\s*$') && l:line =~ '^\S'
            let l:is_header = 1
        else
            let l:is_header = 0
        endif
        if l:is_header == 1 && l:fenced_block == 0 && l:front_matter == 0
            " append line to location list
            let l:item = {'lnum': i, 'text': l:line, 'valid': 1, 'bufnr': l:bufnr, 'col': 1}
            let l:header_list = l:header_list + [l:item]
            " set header number of the cursor position
            if l:cursor_header == 0
                if i == l:cursor_line
                    let l:cursor_header = len(l:header_list)
                elseif i > l:cursor_line
                    let l:cursor_header = len(l:header_list) - 1
                endif
            endif
            " keep track of the longest header size (heading level + title)
            let l:total_len = stridx(l:line, ' ') + strdisplaywidth(l:line)
            if l:total_len > l:header_max_len
                let l:header_max_len = l:total_len
            endif
        endif
    endfor
    call setloclist(0, l:header_list)
    if len(l:header_list) == 0
        echomsg "Toc: No headers."
        return
    endif

    if l:window_type ==# 'horizontal'
        lopen
    elseif l:window_type ==# 'vertical'
        vertical topleft lopen
        " Reposition after qf
        execute "normal! \<C-W>H"

        " auto-fit toc window when possible to shrink it
        if (&columns/2) > l:header_max_len && l:vim_markdown_toc_autofit == 1
            execute 'vertical resize ' . (l:header_max_len + 1)
        else
            execute 'vertical resize ' . (&columns/2)
        endif
    else
        lopen
    endif
    setlocal modifiable
    setlocal filetype=toc
    let b:toc_filename = l:filename
    for i in range(1, line('$'))
        " this is the location-list data for the current item
        let d = getloclist(0)[i-1]
        " atx headers
        if match(d.text, "^#") > -1
            let l:level = len(matchstr(d.text, '#*', 'g'))-1
            let d.text = substitute(d.text, '\v^#*[ ]*', '', '')
            let d.text = substitute(d.text, '\v[ ]*#*$', '', '')
        " setex headers
        else
            let l:next_line = getbufline(d.bufnr, d.lnum+1)
            if match(l:next_line, "=") > -1
                let l:level = 0
            elseif match(l:next_line, "-") > -1
                let l:level = 1
            endif
        endif
        call setline(i, repeat('  ', l:level). d.text)
    endfor
    setlocal nomodified
    setlocal nomodifiable
    setlocal foldlevel=99
    setlocal foldmethod=indent
    execute 'normal! ' . l:cursor_header . 'G'
    .ll
    execute "normal! zvjzvzczOkzt\<C-W>p"
endfunction

" Convert Setex headers in range `line1 .. line2` to Atx.
" Return the number of conversions.
function! s:SetexToAtx(line1, line2)
    let l:originalNumLines = line('$')
    execute 'silent! ' . a:line1 . ',' . a:line2 . 'substitute/\v(.*\S.*)\n\=+$/# \1/'
    execute 'silent! ' . a:line1 . ',' . a:line2 . 'substitute/\v(.*\S.*)\n-+$/## \1/'
    return l:originalNumLines - line('$')
endfunction

" If `a:1` is 0, decrease the level of all headers in range `line1 .. line2`.
" Otherwise, increase the level. `a:1` defaults to `0`.
function! s:HeaderDecrease(line1, line2, ...)
    let l:increase = (a:0 > 0 ? a:1 : 0)
    if l:increase
        let l:forbiddenLevel = 6
        let l:replaceLevels = [5, 1]
        let l:levelDelta = 1
    else
        let l:forbiddenLevel = 1
        let l:replaceLevels = [2, 6]
        let l:levelDelta = -1
    endif
    for l:line in range(a:line1, a:line2)
        if join(getline(l:line, l:line + 1), "\n") =~ s:levelRegexpDict[l:forbiddenLevel]
            echomsg 'There is an h' . l:forbiddenLevel . ' at line ' . l:line . '. Aborting.'
            return
        endif
    endfor
    let l:numSubstitutions = s:SetexToAtx(a:line1, a:line2)
    let l:flags = (&gdefault ? '' : 'g')
    for l:level in range(replaceLevels[0], replaceLevels[1], -l:levelDelta)
        execute 'silent! ' . a:line1 . ',' . (a:line2 - l:numSubstitutions) . 'substitute/' . s:levelRegexpDict[l:level] . '/' . repeat('#', l:level + l:levelDelta) . '/' . l:flags
    endfor
endfunction


" Parameters:
"
" - step +1 for right, -1 for left
"
" TODO: multiple lines.
function! s:FindCornerOfSyntax(lnum, col, step)
    let l:col = a:col
    let l:syn = synIDattr(synID(a:lnum, l:col, 1), 'name')
    while synIDattr(synID(a:lnum, l:col, 1), 'name') ==# l:syn
        let l:col += a:step
    endwhile
    return l:col - a:step
endfunction

" Return the next position of the given syntax name,
" inclusive on the given position.
"
" TODO: multiple lines
function! s:FindNextSyntax(lnum, col, name)
    let l:col = a:col
    let l:step = 1
    while synIDattr(synID(a:lnum, l:col, 1), 'name') !=# a:name
        let l:col += l:step
    endwhile
    return [a:lnum, l:col]
endfunction

function! s:FindCornersOfSyntax(lnum, col)
    return [s:FindLeftOfSyntax(a:lnum, a:col), s:FindRightOfSyntax(a:lnum, a:col)]
endfunction

function! s:FindRightOfSyntax(lnum, col)
    return s:FindCornerOfSyntax(a:lnum, a:col, 1)
endfunction

function! s:FindLeftOfSyntax(lnum, col)
    return s:FindCornerOfSyntax(a:lnum, a:col, -1)
endfunction

" Returns:
"
" - a string with the the URL for the link under the cursor
" - an empty string if the cursor is not on a link
"
" TODO
" - multiline support
" - give an error if the separator does is not on a link
function! s:Markdown_GetUrlForPosition(lnum, col)
    let l:lnum = a:lnum
    let l:col = a:col
    let l:syn = synIDattr(synID(l:lnum, l:col, 1), 'name')

    if l:syn ==# 'mkdInlineURL' || l:syn ==# 'mkdURL' || l:syn ==# 'mkdLinkDefTarget'
        " Do nothing.
    elseif l:syn ==# 'mkdLink'
        let [l:lnum, l:col] = s:FindNextSyntax(l:lnum, l:col, 'mkdURL')
        let l:syn = 'mkdURL'
    elseif l:syn ==# 'mkdDelimiter'
        let l:line = getline(l:lnum)
        let l:char = l:line[col - 1]
        if l:char ==# '<'
            let l:col += 1
        elseif l:char ==# '>' || l:char ==# ')'
            let l:col -= 1
        elseif l:char ==# '[' || l:char ==# ']' || l:char ==# '('
            let [l:lnum, l:col] = s:FindNextSyntax(l:lnum, l:col, 'mkdURL')
        else
            return ''
        endif
    else
        return ''
    endif

    let [l:left, l:right] = s:FindCornersOfSyntax(l:lnum, l:col)
    return getline(l:lnum)[l:left - 1 : l:right - 1]
endfunction

" Front end for GetUrlForPosition.
function! s:OpenUrlUnderCursor()
    let l:url = s:Markdown_GetUrlForPosition(line('.'), col('.'))
    if l:url != ''
        call netrw#BrowseX(l:url, 0)
    else
        echomsg 'The cursor is not on a link.'
    endif
endfunction

" We need a definition guard because we invoke 'edit' which will reload this
" script while this function is running. We must not replace it.
if !exists('*s:EditUrlUnderCursor')
    function s:EditUrlUnderCursor()
        let l:url = s:Markdown_GetUrlForPosition(line('.'), col('.'))
        if l:url != ''
            if get(g:, 'vim_markdown_autowrite', 0)
                write
            endif
            let l:anchor = ''
            if get(g:, 'vim_markdown_follow_anchor', 0)
                let l:parts = split(l:url, '#', 1)
                if len(l:parts) == 2
                    let [l:url, l:anchor] = parts
                    let l:anchorexpr = get(g:, 'vim_markdown_anchorexpr', '')
                    if l:anchorexpr != ''
                        let l:anchor = eval(substitute(
                            \ l:anchorexpr, 'v:anchor',
                            \ escape('"'.l:anchor.'"', '"'), ''))
                    endif
                endif
            endif
            if l:url != ''
                let l:ext = ''
                if get(g:, 'vim_markdown_no_extensions_in_markdown', 0)
                    " use another file extension if preferred
                    if exists('g:vim_markdown_auto_extension_ext')
                        let l:ext = '.'.g:vim_markdown_auto_extension_ext
                    else
                        let l:ext = '.md'
                    endif
                endif
                let l:url = fnameescape(fnamemodify(expand('%:h').'/'.l:url.l:ext, ':.'))
                let l:editmethod = ''
                " determine how to open the linked file (split, tab, etc)
                if exists('g:vim_markdown_edit_url_in')
                  if g:vim_markdown_edit_url_in == 'tab'
                    let l:editmethod = 'tabnew'
                  elseif g:vim_markdown_edit_url_in == 'vsplit'
                    let l:editmethod = 'vsp'
                  elseif g:vim_markdown_edit_url_in == 'hsplit'
                    let l:editmethod = 'sp'
                  else
                    let l:editmethod = 'edit'
                  endif
                else
                  " default to current buffer
                  let l:editmethod = 'edit'
                endif
                execute l:editmethod l:url
            endif
            if l:anchor != ''
                silent! execute '/'.l:anchor
            endif
        else
            echomsg 'The cursor is not on a link.'
        endif
    endfunction
endif

function! s:Markdown_ShouldIndent()
    let l:line = getline('.')
    let l:is_bullet = '^\s*[-+*.|]\%( \[.\]\)\?\s*.*$'
    let l:no_text_yet = '^\s*[-+*.|]\%( \[.\]\)\?\s*$'

    let l:beginning_line = l:line[:col('.')-1]
    let l:is_not_letters = '^\s*\%(\|[-+*.|]\%(\| \[.\]\)\)\?$'

    return l:line =~ l:is_bullet && (l:line =~ l:no_text_yet || l:beginning_line =~ l:is_not_letters)
endfunction

function! s:Markdown_ModifyBullet(direction, ...)
    let l:line_nb = (a:0 > 0 ? a:1 : line('.'))

    let l:line = getline(l:line_nb)
    let l:bullets = ['-', '+', '*', '.', '|']
    let l:regex = '^\s*\([-+*.|]\)\%(\s\+.*\)\?$'

    let l:match = matchlist(l:line, l:regex)
    if empty(l:match) | return | endif

    let l:bullet = l:match[1]
    let l:index = index(l:bullets, l:bullet) + a:direction

    " Don't modify bullet if on first column and going left
    if a:direction == -1 && stridx(l:line, l:bullet) == 0 | return | endif

    let l:bullet = (l:bullet == '.' ? '\V.' : l:bullet)
    let l:new_bullet = l:bullets[l:index % len(l:bullets)]
    let l:new_line = substitute(l:line, l:bullet, l:new_bullet, "")
    call setline(l:line_nb, l:new_line)
endfunction

function! s:Markdown_RemoveBullet()
    if getline('.') =~ '^\s*[-+*.|]\s*$'

        let l:line_to_bullet = matchlist(getline('.'), '^\(\s*[-+*.|]\).*$')[1]
        let l:len_line = len(l:line_to_bullet)

        if getline(line('.')+1)[: l:len_line-1] !=# l:line_to_bullet
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


" TodoList Function {{{1

" Sets the item done
function! s:TodoList_SetItemDone(lineno)
    let l:line = getline(a:lineno)
    call setline(a:lineno, substitute(l:line, '^\(\s*\%([-+*.|]\|\d\+\.\) \)\[[^X]\]', '\1[X]', ''))
endfunction


" Sets the item not done
function! s:TodoList_SetItemNotDone(lineno)
    let l:line = getline(a:lineno)
    call setline(a:lineno, substitute(l:line, '^\(\s*\%([-+*.|]\|\d\+\.\) \)\[[-X]\]', '\1[ ]', ''))
endfunction


" Sets the item in progress
function! s:TodoList_SetItemInProg(lineno)
    let l:line = getline(a:lineno)
    call setline(a:lineno, substitute(l:line, '^\(\s*\%([-+*.|]\|\d\+\.\) \)\[[^X]\]', '\1[-]', ''))
endfunction


" Checks that line is a todo list item
function! s:TodoList_LineIsItem(line)
    return a:line =~ '^\s*\%([-+*.|]\|\d\+\.\) \[.\].*'
endfunction


" Checks that item is not done
function! s:TodoList_ItemIsNotDone(line)
    return a:line =~ '^\s*\%([-+*.|]\|\d\+\.\) \[[^X]\].*'
endfunction


" Checks that item is done
function! s:TodoList_ItemIsDone(line)
    return a:line =~ '^\s*\%([-+*.|]\|\d\+\.\) \[X\].*'
endfunction


" Returns the line number of the parent
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


" Returns the line number of the last child
function! s:TodoList_FindLastChild(lineno)
    if a:lineno == line('$') | return a:lineno | endif
    let l:indent = indent(a:lineno)
    let l:last_child_lineno = a:lineno

    for current_line in range (a:lineno + 1, line('$'))
        if s:TodoList_LineIsItem(getline(current_line)) && indent(current_line) > l:indent
            let l:last_child_lineno = current_line
        else
            break
        endif
    endfor

    return l:last_child_lineno
endfunction


" Marks the parent done if all children are done
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


" Applies the function for each child
function! s:TodoList_ForEachChild(lineno, function)
    let l:last_child_lineno = s:TodoList_FindLastChild(a:lineno)

    " Apply the function on children prior to the item.
    " This order is required for proper work of the items moving on toggle
    for current_line in range(a:lineno, l:last_child_lineno)
        call call(a:function, [current_line])
    endfor
endfunction


" Creates a new item above the current line
function! s:TodoList_CreateNewItemAbove()
    normal! O
    call s:TodoList_CreateNewItem(line('.'))
    startinsert!
endfunction


" Creates a new item below the current line
function! s:TodoList_CreateNewItemBelow()
    normal! o
    call s:TodoList_CreateNewItem(line('.')-1)
    startinsert!
endfunction


" Creates a new item in the current line
function! s:TodoList_CreateNewItem(update_line)
    " If prev line is empty item, delete it
    if getline(line('.') - 1) =~ '^\s*\%([-+*.|]\|\d\+\.\) \[[ X ]\]\s*$'
        call setline(line('.') - 1, '')
        call s:TodoList_UpdateParent(line('.') - 2)
    endif

    let l:prev_line_non_empty_nb = line('.') - 1
    while l:prev_line_non_empty_nb > 0 && getline(l:prev_line_non_empty_nb) =~ '^\s*$'
        let l:prev_line_non_empty_nb -= 1
    endwhile

    let l:prev_line_non_empty = getline(l:prev_line_non_empty_nb)
    if l:prev_line_non_empty =~ '^\s*\d\+\. \[[X ]\] '
        let l:beg_ind = match(l:prev_line_non_empty, '\d')
        let l:end_ind = match(l:prev_line_non_empty, '\.')
        let l:bullet_nb = str2nr(l:prev_line_non_empty[l:beg_ind: l:end_ind-1]) + 1
        let l:indent = l:beg_ind > 0 ? l:prev_line_non_empty[:l:beg_ind-1] : ''
        call setline(line('.'), l:indent . l:bullet_nb . ". [ ] " . getline('.'))
        startinsert!
        return
    endif

    " If previous line is an item, copy its bullet type and indentation by
    " copying the beginning of the line
    let l:prev_line = getline(line('.')-1)
    if s:TodoList_LineIsItem(l:prev_line)
        let l:end_index = match(l:prev_line, '\] ')
        call setline(line('.'), l:prev_line[:l:end_index+1] . getline('.'))
        call s:TodoList_SetItemNotDone(line('.'))

        " If prev line now ends with a space, remove it
        if l:prev_line[-1:] == ' ' | call setline(line('.')-1, l:prev_line[:-2]) | endif
    else
        call setline(line('.'), '- [ ] ' . getline('.'))
    endif

    call s:TodoList_UpdateParent(a:update_line)
    startinsert!
endfunction


" Moves the cursor to the next item
function! s:TodoList_GoToNextItem(count)
    let l:saved_shortmess = &shortmess
    set shortmess+=s
    normal! $
    silent! exec '/^\s*\%([-+*.|]\|\d\+\.\) \[.\]'
    for i in range(a:count-1)
        keepjumps normal! nw
    endfor
    silent! exec 'noh'
    normal! f]2l
    let &shortmess = l:saved_shortmess
endfunction


" Moves the cursor to the previous item
function! s:TodoList_GoToPreviousItem(count)
    let l:saved_shortmess = &shortmess
    set shortmess+=s
    normal! 0
    silent! exec '?^\s*\%([-+*.|]\|\d\+\.\) \[.\]'
    for i in range(a:count-1)
        keepjumps normal! 0nw
    endfor
    silent! exec 'noh'
    normal! f]2l
    let &shortmess = l:saved_shortmess
endfunction


" Moves the cursor to the next base item
function! s:TodoList_GoToNextBaseItem(mode)
    if a:mode ==# 'v' | execute "normal! gv" | endif
    normal! $
    silent! exec '/^\%([-+*.|]\|\d\+\.\) \[.\]'
    silent! exec 'noh'
    normal! l
endfunction


" Moves the cursor to the previous base item
function! s:TodoList_GoToPreviousBaseItem(mode)
    if a:mode ==# 'v' | execute "normal! gv" | endif
    normal! 0
    silent! exec '?^\%([-+*.|]\|\d\+\.\) \[.\]'
    silent! exec 'noh'
    normal! l
endfunction


" Get line number of the item containing the given line number
function! s:TodoList_GetLineItem(line)
    let l:item_line = a:line
    while l:item_line > -1 && !s:TodoList_LineIsItem(getline(l:item_line))
        let l:item_line -= 1
    endwhile

    return l:item_line
endfunction


" Moves the cursor to the next sibling item
function! s:TodoList_GoToNextSiblingItem(mode)
    if a:mode ==# 'v' | execute "normal! gv" | endif

    let l:curr_item_line = s:TodoList_GetLineItem(line('.'))
    if l:curr_item_line < 0 | echo 'No next sibling item' | return | endif

    let l:indent = indent(l:curr_item_line)
    let l:next_sibling_line = line('.') + 1

    while l:next_sibling_line < line('$') &&
            \ (!s:TodoList_LineIsItem(getline(l:next_sibling_line)) || indent(l:next_sibling_line) > l:indent)
        let l:next_sibling_line += 1
    endwhile

    if indent(l:next_sibling_line) == l:indent
        call cursor(l:next_sibling_line, 1)
        normal! ^
    else
        echo 'No next sibling item'
    endif
endfunction


" Moves the cursor to the previous sibling item
function! s:TodoList_GoToPreviousSiblingItem(mode)
    if a:mode ==# 'v' | execute "normal! gv" | endif

    let l:curr_item_line = s:TodoList_GetLineItem(line('.'))
    if l:curr_item_line < 0 | echo 'No prev sibling item' | return | endif

    let l:indent = indent(l:curr_item_line)
    let l:prev_sibling_line = l:curr_item_line - 1

    while l:prev_sibling_line > -1 &&
            \ (!s:TodoList_LineIsItem(getline(l:prev_sibling_line)) || indent(l:prev_sibling_line) > l:indent)
        let l:prev_sibling_line -= 1
    endwhile

    if indent(l:prev_sibling_line) == l:indent
        call cursor(l:prev_sibling_line, 1)
        normal! ^
    else
        echo 'No prev sibling item'
    endif
endfunction

" Move cursor to parent item
function! s:TodoList_GoToParentItem(mode)
    if a:mode ==# 'v' | execute "normal! gv" | endif

    let l:curr_item_line = s:TodoList_GetLineItem(line('.'))
    let l:indent = indent(l:curr_item_line)
    if l:curr_item_line < 0 || l:indent == 0 | echo 'No parent item' | return | endif

    let l:parent_line = l:curr_item_line - 1
    while l:parent_line > -1 &&
            \ (!s:TodoList_LineIsItem(getline(l:parent_line)) || indent(l:parent_line) >= l:indent)
        let l:parent_line -= 1
    endwhile

    if l:parent_line > 0
        call cursor(l:parent_line, 1)
        normal! ^
    else
        echo 'No parent item'
    endif
endfunction

" Move cursor to next undone item
function! s:TodoList_GoToNextUndoneItem(mode)
    if a:mode ==# 'v' | execute "normal! gv" | endif
    call s:TodoList_GoToNextItem(1)
    while !s:TodoList_ItemIsNotDone(getline('.'))
        call s:TodoList_GoToNextItem(1)
    endwhile
endfunction

" Move cursor to prev undone item
function! s:TodoList_GoToPrevUndoneItem(mode)
    if a:mode ==# 'v' | execute "normal! gv" | endif
    call s:TodoList_GoToPreviousItem(1)
    while !s:TodoList_ItemIsNotDone(getline('.'))
        call s:TodoList_GoToPreviousItem(1)
    endwhile
endfunction

" Toggles todo list item
function! s:TodoList_ToggleItem()
    let l:line = getline('.')
    let l:lineno = line('.')

    " Store current cursor position
    let l:cursor_pos = getcurpos()

    if s:TodoList_ItemIsNotDone(l:line) == 1
        call s:TodoList_ForEachChild(l:lineno, 's:TodoList_SetItemDone')
    elseif s:TodoList_ItemIsDone(l:line) == 1
        call s:TodoList_ForEachChild(l:lineno, 's:TodoList_SetItemNotDone')
    endif

    call s:TodoList_UpdateParent(l:lineno)

    " Restore the current position
    " Using the {curswant} value to set the proper column
    call cursor(l:cursor_pos[1], l:cursor_pos[4])
endfunction


function! s:TodoList_SetInProgItem()
    let l:line = getline('.')
    let l:lineno = line('.')

    " Store current cursor position
    let l:cursor_pos = getcurpos()

    if s:TodoList_ItemIsNotDone(l:line) == 1
        call s:TodoList_ForEachChild(l:lineno, 's:TodoList_SetItemInProg')
    endif

    " Restore the current position
    " Using the {curswant} value to set the proper column
    call cursor(l:cursor_pos[1], l:cursor_pos[4])
endfunction


function! s:TodoList_DeleteItem(lineno, update)
    let l:indent = indent(a:lineno)
    execute "normal! :" . a:lineno . "," . s:TodoList_FindLastChild(a:lineno) . "d\<CR>"
    if line('.') < line('$') && l:indent == 0 && getline(a:lineno) == ''
        normal! "_dd
    endif

    if a:update
        " If next indentation is lower, update previous line, else update current line
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
    if line('.') != line('$') && s:TodoList_LineIsItem(getline(line('.')+1))
        normal! j0df]k
    endif

    normal! J
endfunction

function! s:TodoList_ShouldBS()
    return getline('.')[:col('.')-2] =~ '^\s*\%([-+*.|]\|\d\+\.\) \[.\] \?$'
endfunction

function! s:TodoList_BackSpace()
    normal! 0df]
    if getline('.') ==# ' '
        normal! x
    elseif !s:TodoList_LineIsItem(getline(line('.')-1))
        normal! xgP
    endif
endfunction


" Mapping Definition {{{1

function! s:MapKey(lhs, rhs)
    execute "nnoremap <buffer><silent> " . a:lhs . " :call " . a:rhs . "('n')<CR>"
    execute "onoremap <buffer><silent> " . a:lhs . " :call " . a:rhs . "('n')<CR>"
    execute "vnoremap <buffer><silent> " . a:lhs . " :<C-U>call " . a:rhs . "('v')<CR>"
endfunction


function! s:SetCommonMappings()
    noremap <buffer><silent> <leader>c :<C-U>Toc<CR>
    noremap <buffer><silent> <Space> :call <SID>TodoList_ToggleItem()<CR>
    noremap <buffer><silent> g<Space> :call <SID>TodoList_SetInProgItem()<CR>

    nnoremap <buffer><silent> J :call <SID>TodoList_JoinLine()<CR>

    nnoremap <buffer><silent> gx :call <SID>OpenUrlUnderCursor()<CR>
    nnoremap <buffer><silent> ge :call <SID>EditUrlUnderCursor()<CR>

    " Indentation mappings
    nnoremap <buffer><silent> <Plug>Markdown_Indent :call <SID>Markdown_Indent()<CR>
    nnoremap <buffer><silent> <Plug>Markdown_Dedent :call <SID>Markdown_Dedent()<CR>
    nmap <buffer><silent> >> <Plug>Markdown_Indent
    nmap <buffer><silent> << <Plug>Markdown_Dedent

    nnoremap <buffer><silent> > :set opfunc=<SID>Markdown_ModifyIndentRange<CR>g@
    nnoremap <buffer><silent> < :set opfunc=<SID>Markdown_ModifyDedentRange<CR>g@
    vnoremap <buffer><silent> > :<C-u>call <SID>Markdown_ModifyIndentRange('visual')<CR>
    vnoremap <buffer><silent> < :<C-u>call <SID>Markdown_ModifyDedentRange('visual')<CR>

    inoremap <buffer><silent>       <C-T> <C-T><C-O>:call <SID>Markdown_ModifyBullet(1) \| call <SID>TodoList_UpdateParents(-1, 0)<CR>
    inoremap <buffer><silent><expr> <C-D> col('.')>strlen(getline('.')) ? "<C-O>:call <SID>Markdown_ModifyBullet(-1) \| call <SID>TodoList_UpdateParents(-1, 0)<CR><C-D>" : "<Del>"

    inoremap <buffer><silent><expr> <Tab>   <SID>Markdown_ShouldIndent() ? "<C-T><C-\><C-O>:call <SID>Markdown_ModifyBullet(1) \| call <SID>TodoList_UpdateParents(-1, 0)<CR>" : "<Tab>"
    inoremap <buffer><silent>       <S-Tab> <C-O>:call <SID>Markdown_ModifyBullet(-1) \| call <SID>TodoList_UpdateParents(-1, 0)<CR><C-D>
endfunction


" Sets mapping for normal navigation and editing mode
function! s:SetMarkdownMode()
    if exists('s:cursorline_backup')
        let &cursorline = s:cursorline_backup
    endif
    if exists('s:autoindent_backup')
        let &autoindent = s:autoindent_backup
    endif
    setlocal formatoptions-=c
    setlocal comments+=b:*,b:+,b:-,b:.,b:\|

    let b:todo_mode = 0

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

    call s:MapKey(']]', "<SID>Markdown_GoToNextHeader")
    call s:MapKey('[[', "<SID>Markdown_GoToPreviousHeader")
    call s:MapKey('][', "<SID>Markdown_GoToNextSiblingHeader")
    call s:MapKey('[]', "<SID>Markdown_GoToPreviousSiblingHeader")
    call s:MapKey(']u', "<SID>Markdown_GoToParentHeader")
    call s:MapKey(']y', "<SID>Markdown_GoToCurrHeader")

    nnoremap <buffer><silent> o A<CR>
    nnoremap <buffer><silent> O kA<CR>
    inoremap <buffer><silent> <CR> <C-O>:call <SID>Markdown_RemoveBullet()<CR><CR>
    inoremap <buffer><silent> <BS> <C-R>=AutoPairsDelete()<CR>

    noremap  <buffer><silent> <leader>e :call <SID>SetTodoMode()<CR>
endfunction

" Sets mappings for faster item navigation and editing
function! s:SetTodoMode()
    let s:cursorline_backup = &cursorline
    let s:autoindent_backup = &autoindent
    setlocal cursorline
    setlocal noautoindent
    setlocal formatoptions+=c
    setlocal comments-=b:*,b:+,b:-,b:.,b:\|

    let b:todo_mode = 1

    silent! unmap <buffer> ]]
    silent! unmap <buffer> [[
    silent! unmap <buffer> ][
    silent! unmap <buffer> []
    silent! unmap <buffer> ]u
    silent! unmap <buffer> ]y
    silent! iunmap <buffer> <CR>

    nnoremap <buffer><silent> o :call <SID>TodoList_CreateNewItemBelow()<CR>
    nnoremap <buffer><silent> O :call <SID>TodoList_CreateNewItemAbove()<CR>
    nnoremap <buffer><silent> j :<C-U>call <SID>TodoList_GoToNextItem(v:count1)<CR>
    nnoremap <buffer><silent> k :<C-U>call <SID>TodoList_GoToPreviousItem(v:count1)<CR>

    nnoremap <buffer><silent> dd        :call <SID>TodoList_DeleteItem(line('.'), 1) \| call repeat#set("dd", -1)<CR>
    nnoremap <buffer><silent> <leader>d :call <SID>TodoList_CleanItemsDone()<CR>

    nnoremap <buffer><silent> - :m .+1 \| call <SID>TodoList_UpdateParents(-1, 1, -2)<CR>
    nnoremap <buffer><silent> _ :m .-2 \| call <SID>TodoList_UpdateParents(-1, 1, 2)<CR>

    inoremap <buffer><silent><expr> <BS> <SID>TodoList_ShouldBS() ? "<C-\><C-O>:call <SID>TodoList_BackSpace()<CR><BS>" : "<C-R>=AutoPairsDelete()<CR>"
    inoremap <buffer><silent> <CR> <C-O>:call <SID>TodoList_MakeHeader()<CR><CR><C-O>:call <SID>TodoList_CreateNewItem(line('.')-1)<CR>
    nmap <buffer><silent> <Tab>   <Plug>Markdown_Indent
    nmap <buffer><silent> <S-Tab> <Plug>Markdown_Dedent

    call s:MapKey(']]', "<SID>TodoList_GoToNextBaseItem")
    call s:MapKey('[[', "<SID>TodoList_GoToPreviousBaseItem")
    call s:MapKey('][', "<SID>TodoList_GoToNextSiblingItem")
    call s:MapKey('[]', "<SID>TodoList_GoToPreviousSiblingItem")
    call s:MapKey(']u', "<SID>TodoList_GoToParentItem")
    call s:MapKey('[i', "<SID>TodoList_GoToPrevUndoneItem")
    call s:MapKey(']i', "<SID>TodoList_GoToNextUndoneItem")

    noremap  <buffer><silent> <leader>e :silent call <SID>SetMarkdownMode()<CR>
endfunction

command! -buffer -range=% HeaderDecrease call s:HeaderDecrease(<line1>, <line2>)
command! -buffer -range=% HeaderIncrease call s:HeaderDecrease(<line1>, <line2>, 1)
command! -buffer -range=% SetexToAtx call s:SetexToAtx(<line1>, <line2>)
command! -buffer Toc call s:Toc()
command! -buffer Toch call s:Toc('horizontal')
command! -buffer Tocv call s:Toc('vertical')


setlocal conceallevel=2 concealcursor=c
setlocal shiftwidth=2 tabstop=2 expandtab


let b:autopairs_map_CR = 0
let b:autopairs_map_BS = 0
call s:SetCommonMappings()
if expand('%:t') =~ '.*\.todo' || expand('%:t') =~ 'ToDo'
    call s:SetTodoMode()
else
    call s:SetMarkdownMode()
endif

" Modeline {{{1
" vim: foldenable foldmethod=marker
