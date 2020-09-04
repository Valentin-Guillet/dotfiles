"TODO print messages when on visual mode. I only see VISUAL, not the messages.

" Function interface phylosophy:
"
" - functions take arbitrary line numbers as parameters.
"    Current cursor line is only a suitable default parameter.
"
" - only functions that bind directly to user actions:
"
"    - print error messages.
"       All intermediate functions limit themselves return `0` to indicate an error.
"
"    - move the cursor. All other functions do not move the cursor.
"
" This is how you should view headers for the header mappings:
"
"   |BUFFER
"   |
"   |Outside any header
"   |
" a-+# a
"   |
"   |Inside a
"   |
" a-+
" b-+## b
"   |
"   |inside b
"   |
" b-+
" c-+### c
"   |
"   |Inside c
"   |
" c-+
" d-|# d
"   |
"   |Inside d
"   |
" d-+
" e-|e
"   |====
"   |
"   |Inside e
"   |
" e-+

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

" Returns the line number of the first header before `line`, called the
" current header.
"
" If there is no current header, return `0`.
"
" @param a:1 The line to look the header of. Default value: `getpos('.')`.
"
function! s:GetHeaderLineNum(...)
    if a:0 == 0
        let l:l = line('.')
    else
        let l:l = a:1
    endif
    while(l:l > 0)
        if join(getline(l:l, l:l + 1), "\n") =~ s:headersRegexp
            return l:l
        endif
        let l:l -= 1
    endwhile
    return 0
endfunction

" -  if inside a header goes to it.
"    Return its line number.
"
" -  if on top level outside any headers,
"    print a warning
"    Return `0`.
"
function! s:MoveToCurHeader()
    let l:lineNum = s:GetHeaderLineNum()
    if l:lineNum != 0
        call cursor(l:lineNum, 1)
    else
        echo 'Outside any header'
        "normal! gg
    endif
    return l:lineNum
endfunction

" Move cursor to next header of any level.
"
" If there are no more headers, print a warning.
"
function! s:MoveToNextHeader()
    if search(s:headersRegexp, 'W') == 0
        "normal! G
        echo 'No next header'
    endif
endfunction

" Move cursor to previous header (before current) of any level.
"
" If it does not exist, print a warning.
"
function! s:MoveToPreviousHeader()
    let l:curHeaderLineNumber = s:GetHeaderLineNum()
    let l:noPreviousHeader = 0
    if l:curHeaderLineNumber <= 1
        let l:noPreviousHeader = 1
    else
        let l:previousHeaderLineNumber = s:GetHeaderLineNum(l:curHeaderLineNumber - 1)
        if l:previousHeaderLineNumber == 0
            let l:noPreviousHeader = 1
        else
            call cursor(l:previousHeaderLineNumber, 1)
        endif
    endif
    if l:noPreviousHeader
        echo 'No previous header'
    endif
endfunction

" - if line is inside a header, return the header level (h1 -> 1, h2 -> 2, etc.).
"
" - if line is at top level outside any headers, return `0`.
"
function! s:GetHeaderLevel(...)
    if a:0 == 0
        let l:line = line('.')
    else
        let l:line = a:1
    endif
    let l:linenum = s:GetHeaderLineNum(l:line)
    if l:linenum != 0
        return s:GetLevelOfHeaderAtLine(l:linenum)
    else
        return 0
    endif
endfunction

" Returns the level of the header at the given line.
"
" If there is no header at the given line, returns `0`.
"
function! s:GetLevelOfHeaderAtLine(linenum)
    let l:lines = join(getline(a:linenum, a:linenum + 1), "\n")
    for l:key in keys(s:levelRegexpDict)
        if l:lines =~ get(s:levelRegexpDict, l:key)
            return l:key
        endif
    endfor
    return 0
endfunction

" Move cursor to parent header of the current header.
"
" If it does not exit, print a warning and do nothing.
"
function! s:MoveToParentHeader()
    let l:linenum = s:GetParentHeaderLineNumber()
    if l:linenum != 0
        call cursor(l:linenum, 1)
    else
        echo 'No parent header'
    endif
endfunction

" Return the line number of the parent header of line `line`.
"
" If it has no parent, return `0`.
"
function! s:GetParentHeaderLineNumber(...)
    if a:0 == 0
        let l:line = line('.')
    else
        let l:line = a:1
    endif
    let l:level = s:GetHeaderLevel(l:line)
    if l:level > 1
        let l:linenum = s:GetPreviousHeaderLineNumberAtLevel(l:level - 1, l:line)
        return l:linenum
    endif
    return 0
endfunction

" Return the line number of the previous header of given level.
" in relation to line `a:1`. If not given, `a:1 = getline()`
"
" `a:1` line is included, and this may return the current header.
"
" If none return 0.
"
function! s:GetNextHeaderLineNumberAtLevel(level, ...)
    if a:0 < 1
        let l:line = line('.')
    else
        let l:line = a:1
    endif
    let l:l = l:line
    while(l:l <= line('$'))
        if join(getline(l:l, l:l + 1), "\n") =~ get(s:levelRegexpDict, a:level)
            return l:l
        endif
        let l:l += 1
    endwhile
    return 0
endfunction

" Return the line number of the previous header of given level.
" in relation to line `a:1`. If not given, `a:1 = getline()`
"
" `a:1` line is included, and this may return the current header.
"
" If none return 0.
"
function! s:GetPreviousHeaderLineNumberAtLevel(level, ...)
    if a:0 == 0
        let l:line = line('.')
    else
        let l:line = a:1
    endif
    let l:l = l:line
    while(l:l > 0)
        if join(getline(l:l, l:l + 1), "\n") =~ get(s:levelRegexpDict, a:level)
            return l:l
        endif
        let l:l -= 1
    endwhile
    return 0
endfunction

" Move cursor to next sibling header.
"
" If there is no next siblings, print a warning and don't move.
"
function! s:MoveToNextSiblingHeader()
    let l:curHeaderLineNumber = s:GetHeaderLineNum()
    let l:curHeaderLevel = s:GetLevelOfHeaderAtLine(l:curHeaderLineNumber)
    let l:curHeaderParentLineNumber = s:GetParentHeaderLineNumber()
    let l:nextHeaderSameLevelLineNumber = s:GetNextHeaderLineNumberAtLevel(l:curHeaderLevel, l:curHeaderLineNumber + 1)
    let l:noNextSibling = 0
    if l:nextHeaderSameLevelLineNumber == 0
        let l:noNextSibling = 1
    else
        let l:nextHeaderSameLevelParentLineNumber = s:GetParentHeaderLineNumber(l:nextHeaderSameLevelLineNumber)
        if l:curHeaderParentLineNumber == l:nextHeaderSameLevelParentLineNumber
            call cursor(l:nextHeaderSameLevelLineNumber, 1)
        else
            let l:noNextSibling = 1
        endif
    endif
    if l:noNextSibling
        echo 'No next sibling header'
    endif
endfunction

" Move cursor to previous sibling header.
"
" If there is no previous siblings, print a warning and do nothing.
"
function! s:MoveToPreviousSiblingHeader()
    let l:curHeaderLineNumber = s:GetHeaderLineNum()
    let l:curHeaderLevel = s:GetLevelOfHeaderAtLine(l:curHeaderLineNumber)
    let l:curHeaderParentLineNumber = s:GetParentHeaderLineNumber()
    let l:previousHeaderSameLevelLineNumber = s:GetPreviousHeaderLineNumberAtLevel(l:curHeaderLevel, l:curHeaderLineNumber - 1)
    let l:noPreviousSibling = 0
    if l:previousHeaderSameLevelLineNumber == 0
        let l:noPreviousSibling = 1
    else
        let l:previousHeaderSameLevelParentLineNumber = s:GetParentHeaderLineNumber(l:previousHeaderSameLevelLineNumber)
        if l:curHeaderParentLineNumber == l:previousHeaderSameLevelParentLineNumber
            call cursor(l:previousHeaderSameLevelLineNumber, 1)
        else
            let l:noPreviousSibling = 1
        endif
    endif
    if l:noPreviousSibling
        echo 'No previous sibling header'
    endif
endfunction

function! s:Toc(...)
    if a:0 > 0
        let l:window_type = a:1
    else
        let l:window_type = 'vertical'
    endif


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
            if l:fenced_block == 0
                let l:fenced_block = 1
            elseif l:fenced_block == 1
                let l:fenced_block = 0
            endif
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
        echom "Toc: No headers."
        return
    endif

    if l:window_type ==# 'horizontal'
        lopen
    elseif l:window_type ==# 'vertical'
        vertical topleft lopen
        " auto-fit toc window when possible to shrink it
        if (&columns/2) > l:header_max_len && l:vim_markdown_toc_autofit == 1
            execute 'vertical resize ' . (l:header_max_len + 1)
        else
            execute 'vertical resize ' . (&columns/2)
        endif
    elseif l:window_type ==# 'tab'
        tab lopen
    else
        lopen
    endif
    setlocal modifiable
    setlocal filetype=toc
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
endfunction

" Convert Setex headers in range `line1 .. line2` to Atx.
"
" Return the number of conversions.
"
function! s:SetexToAtx(line1, line2)
    let l:originalNumLines = line('$')
    execute 'silent! ' . a:line1 . ',' . a:line2 . 'substitute/\v(.*\S.*)\n\=+$/# \1/'
    execute 'silent! ' . a:line1 . ',' . a:line2 . 'substitute/\v(.*\S.*)\n-+$/## \1/'
    return l:originalNumLines - line('$')
endfunction

" If `a:1` is 0, decrease the level of all headers in range `line1 .. line2`.
"
" Otherwise, increase the level. `a:1` defaults to `0`.
"
function! s:HeaderDecrease(line1, line2, ...)
    if a:0 > 0
        let l:increase = a:1
    else
        let l:increase = 0
    endif
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

" Format table under cursor.
"
" Depends on Tabularize.
"
function! s:TableFormat()
    let l:pos = getpos('.')
    normal! {
    " Search instead of `normal! j` because of the table at beginning of file edge case.
    call search('|')
    normal! j
    " Remove everything that is not a pipe, colon or hyphen next to a colon othewise
    " well formated tables would grow because of addition of 2 spaces on the separator
    " line by Tabularize /|.
    let l:flags = (&gdefault ? '' : 'g')
    execute 's/\(:\@<!-:\@!\|[^|:-]\)//e' . l:flags
    execute 's/--/-/e' . l:flags
    Tabularize /|
    " Move colons for alignment to left or right side of the cell.
    execute 's/:\( \+\)|/\1:|/e' . l:flags
    execute 's/|\( \+\):/|:\1/e' . l:flags
    execute 's/ /-/' . l:flags
    call setpos('.', l:pos)
endfunction

" Wrapper to do move commands in visual mode.
"
function! s:VisMove(f)
    norm! gv
    call function(a:f)()
endfunction

" Map in both normal and visual modes.
"
function! s:MapNormVis(rhs,lhs)
    execute 'nn <buffer><silent> ' . a:rhs . ' :call ' . a:lhs . '()<cr>'
    execute 'vn <buffer><silent> ' . a:rhs . ' <esc>:call s:VisMove(''' . a:lhs . ''')<cr>'
endfunction

" Parameters:
"
" - step +1 for right, -1 for left
"
" TODO: multiple lines.
"
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
"
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
"
" - multiline support
" - give an error if the separator does is not on a link
"
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
"
function! s:OpenUrlUnderCursor()
    let l:url = s:Markdown_GetUrlForPosition(line('.'), col('.'))
    if l:url != ''
        call s:VersionAwareNetrwBrowseX(l:url)
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

function! s:VersionAwareNetrwBrowseX(url)
    if has('patch-7.4.567')
        call netrw#BrowseX(a:url, 0)
    else
        call netrw#NetrwBrowseX(a:url, 0)
    endif
endf

function! s:MapNotHasmapto(lhs, rhs)
    if !hasmapto('<Plug>' . a:rhs)
        execute 'nmap <buffer>' . a:lhs . ' <Plug>' . a:rhs
        execute 'vmap <buffer>' . a:lhs . ' <Plug>' . a:rhs
    endif
endfunction

call s:MapNormVis('<Plug>Markdown_MoveToNextHeader', '<SID>MoveToNextHeader')
call s:MapNormVis('<Plug>Markdown_MoveToPreviousHeader', '<SID>MoveToPreviousHeader')
call s:MapNormVis('<Plug>Markdown_MoveToNextSiblingHeader', '<SID>MoveToNextSiblingHeader')
call s:MapNormVis('<Plug>Markdown_MoveToPreviousSiblingHeader', '<SID>MoveToPreviousSiblingHeader')
call s:MapNormVis('<Plug>Markdown_MoveToParentHeader', '<SID>MoveToParentHeader')
call s:MapNormVis('<Plug>Markdown_MoveToCurHeader', '<SID>MoveToCurHeader')
nnoremap <Plug>Markdown_OpenUrlUnderCursor :call <SID>OpenUrlUnderCursor()<cr>
nnoremap <Plug>Markdown_EditUrlUnderCursor :call <SID>EditUrlUnderCursor()<cr>

if !get(g:, 'vim_markdown_no_default_key_mappings', 0)
    call s:MapNotHasmapto(']]', 'Markdown_MoveToNextHeader')
    call s:MapNotHasmapto('[[', 'Markdown_MoveToPreviousHeader')
    call s:MapNotHasmapto('][', 'Markdown_MoveToNextSiblingHeader')
    call s:MapNotHasmapto('[]', 'Markdown_MoveToPreviousSiblingHeader')
    call s:MapNotHasmapto(']u', 'Markdown_MoveToParentHeader')
    call s:MapNotHasmapto(']c', 'Markdown_MoveToCurHeader')
    call s:MapNotHasmapto('gx', 'Markdown_OpenUrlUnderCursor')
    call s:MapNotHasmapto('ge', 'Markdown_EditUrlUnderCursor')
endif

command! -buffer -range=% HeaderDecrease call s:HeaderDecrease(<line1>, <line2>)
command! -buffer -range=% HeaderIncrease call s:HeaderDecrease(<line1>, <line2>, 1)
command! -buffer -range=% SetexToAtx call s:SetexToAtx(<line1>, <line2>)
command! -buffer TableFormat call s:TableFormat()
command! -buffer Toc call s:Toc()
command! -buffer Toch call s:Toc('horizontal')
command! -buffer Tocv call s:Toc('vertical')
command! -buffer Toct call s:Toc('tab')

" Heavily based on vim-notes - http://peterodding.com/code/vim/notes/
if exists('g:vim_markdown_fenced_languages')
    let s:filetype_dict = {}
    for s:filetype in g:vim_markdown_fenced_languages
        let key = matchstr(s:filetype, "[^=]*")
        let val = matchstr(s:filetype, "[^=]*$")
        let s:filetype_dict[key] = val
    endfor
else
    let s:filetype_dict = {
        \ 'c++': 'cpp',
        \ 'viml': 'vim',
        \ 'bash': 'sh',
        \ 'ini': 'dosini'
    \ }
endif

function! s:MarkdownHighlightSources(force)
    " Syntax highlight source code embedded in notes.
    " Look for code blocks in the current file
    let filetypes = {}
    for line in getline(1, '$')
        let ft = matchstr(line, '```\s*\zs[0-9A-Za-z_+-]*')
        if !empty(ft) && ft !~ '^\d*$' | let filetypes[ft] = 1 | endif
    endfor
    if !exists('b:mkd_known_filetypes')
        let b:mkd_known_filetypes = {}
    endif
    if !exists('b:mkd_included_filetypes')
        " set syntax file name included
        let b:mkd_included_filetypes = {}
    endif
    if !a:force && (b:mkd_known_filetypes == filetypes || empty(filetypes))
        return
    endif

    " Now we're ready to actually highlight the code blocks.
    let startgroup = 'mkdCodeStart'
    let endgroup = 'mkdCodeEnd'
    for ft in keys(filetypes)
        if a:force || !has_key(b:mkd_known_filetypes, ft)
            if has_key(s:filetype_dict, ft)
                let filetype = s:filetype_dict[ft]
            else
                let filetype = ft
            endif
            let group = 'mkdSnippet' . toupper(substitute(filetype, "[+-]", "_", "g"))
            if !has_key(b:mkd_included_filetypes, filetype)
                let include = s:SyntaxInclude(filetype)
                let b:mkd_included_filetypes[filetype] = 1
            else
                let include = '@' . toupper(filetype)
            endif
            let command = 'syntax region %s matchgroup=%s start="^\s*```\s*%s$" matchgroup=%s end="\s*```$" keepend contains=%s%s'
            execute printf(command, group, startgroup, ft, endgroup, include, has('conceal') && get(g:, 'vim_markdown_conceal', 1) && get(g:, 'vim_markdown_conceal_code_blocks', 1) ? ' concealends' : '')
            execute printf('syntax cluster mkdNonListItem add=%s', group)

            let b:mkd_known_filetypes[ft] = 1
        endif
    endfor
endfunction

function! s:SyntaxInclude(filetype)
    " Include the syntax highlighting of another {filetype}.
    let grouplistname = '@' . toupper(a:filetype)
    " Unset the name of the current syntax while including the other syntax
    " because some syntax scripts do nothing when "b:current_syntax" is set
    if exists('b:current_syntax')
        let syntax_save = b:current_syntax
        unlet b:current_syntax
    endif
    try
        execute 'syntax include' grouplistname 'syntax/' . a:filetype . '.vim'
        execute 'syntax include' grouplistname 'after/syntax/' . a:filetype . '.vim'
    catch /E484/
        " Ignore missing scripts
    endtry
    " Restore the name of the current syntax
    if exists('syntax_save')
        let b:current_syntax = syntax_save
    elseif exists('b:current_syntax')
        unlet b:current_syntax
    endif
    return grouplistname
endfunction


function! s:MarkdownRefreshSyntax(force)
    if &filetype =~ 'markdown' && line('$') > 1
        call s:MarkdownHighlightSources(a:force)
    endif
endfunction

function! s:MarkdownClearSyntaxVariables()
    if &filetype =~ 'markdown'
        unlet! b:mkd_included_filetypes
    endif
endfunction

function! s:MarkdownShouldIndent()
    let l:line = getline('.')
    let l:is_bullet = '^\s*[+*-]\s*.*$'
    let l:no_text_yet = '^\s*[+*-]\s*$'

    let l:beginning_line = l:line[:col('.')-1]
    let l:is_not_letters = '^\s*[+*-]\?$'

    return l:line =~ l:is_bullet && (l:line =~ l:no_text_yet || l:beginning_line =~ l:is_not_letters)
endfunction

function! s:MarkdownModifyBullet(direction, ...)
    if a:0 > 0
        let l:line_nb = a:1
    else
        let l:line_nb = '.'
    endif

    let l:line = getline(l:line_nb)
    let l:bullets = ['-', '+', '*']
    let l:regex = '^\s*\([+*-]\)\%(\s\+.*\)\?$'

    let l:match = matchlist(l:line, l:regex)
    if !empty(l:match)
        let l:bullet = l:match[1]
        let l:index = index(l:bullets, l:bullet) + a:direction

        " Don't modify bullet if on first column and going left
        if a:direction == 1 || stridx(l:line, l:bullet) > 1  
            let l:new_bullet = l:bullets[l:index % 3]
            let l:new_line = substitute(l:line, l:bullet, l:new_bullet, "")
            call setline(l:line_nb, l:new_line)
        endif

    endif
endfunction

function! s:MarkdownRemoveBullet()
    if getline('.') =~ '^\s*[+*-]\s*$'

        let l:line_to_bullet = matchlist(getline('.'), '^\(\s*[+*-]\).*$')[1]
        let l:len_line = len(l:line_to_bullet)

        if getline(line('.')+1)[: l:len_line-1] !=# l:line_to_bullet
            normal! 0D
        else
            execute "normal! a\<Space>"
        endif
    
    endif
endfunction

function! s:MarkdownModifyIndentRange(type)
    if a:type ==? 'line'
        let l:min_line = line("'[")
        let l:max_line = line("']")
    else
        let l:min_line = line("'<")
        let l:max_line = line("'>")
    endif

    for l:lnum in range(l:max_line, l:min_line, -1)
        call s:MarkdownModifyBullet(1, l:lnum)
        execute l:lnum . "normal! >>"
    endfor
endfunction

function! s:MarkdownModifyDedentRange(type)
    if a:type ==? 'line'
        let l:min_line = line("'[")
        let l:max_line = line("']")
    else
        let l:min_line = line("'<")
        let l:max_line = line("'>")
    endif

    for l:lnum in range(l:max_line, l:min_line, -1)
        call s:MarkdownModifyBullet(-1, l:lnum)
        execute l:lnum . "normal! <<"
    endfor
endfunction

augroup Mkd
    " These autocmd calling s:MarkdownRefreshSyntax need to be kept in sync with
    " the autocmds calling s:MarkdownSetupFolding in after/ftplugin/markdown.vim.
    autocmd! * <buffer>
    autocmd BufWinEnter <buffer> call s:MarkdownRefreshSyntax(1)
    autocmd BufUnload <buffer> call s:MarkdownClearSyntaxVariables()
    autocmd BufWritePost <buffer> call s:MarkdownRefreshSyntax(0)
    autocmd InsertEnter,InsertLeave <buffer> call s:MarkdownRefreshSyntax(0)
    autocmd CursorHold,CursorHoldI <buffer> call s:MarkdownRefreshSyntax(0)
augroup END


" Activate conceal
setlocal conceallevel=2 concealcursor=nc

" Tabstop and shiftwidth to 2
setlocal shiftwidth=2 tabstop=2


" Custom mappings
noremap  <buffer> <leader>c :Toc<CR>
nnoremap <buffer> o A<CR>
nnoremap <buffer> O kA<CR>

nnoremap <buffer><silent> > :set opfunc=<SID>MarkdownModifyIndentRange<CR>g@
nnoremap <buffer><silent> < :set opfunc=<SID>MarkdownModifyDedentRange<CR>g@
vnoremap <buffer><silent> > :<C-u>call <SID>MarkdownModifyIndentRange('visual')<CR>
vnoremap <buffer><silent> < :<C-u>call <SID>MarkdownModifyDedentRange('visual')<CR>

nnoremap <buffer><silent> <Plug>MarkdownIncrement :call <SID>MarkdownModifyBullet( 1) \| execute "normal! >>" \| call repeat#set("\<Plug>MarkdownIncrement")<CR>
nnoremap <buffer><silent> <Plug>MarkdownDecrement :call <SID>MarkdownModifyBullet(-1) \| execute "normal! <<" \| call repeat#set("\<Plug>MarkdownDecrement")<CR>
nmap >> <Plug>MarkdownIncrement
nmap << <Plug>MarkdownDecrement

inoremap <buffer><silent>       <C-T> <C-O>:call <SID>MarkdownModifyBullet(1)<CR><C-T>
inoremap <buffer><silent><expr> <C-D> col('.')>strlen(getline('.'))?"<C-O>:call <SID>MarkdownModifyBullet(-1)<CR><C-D>":"<Del>"

inoremap <buffer><silent><expr> <Tab>   <SID>MarkdownShouldIndent()?"<C-\><C-O>:call <SID>MarkdownModifyBullet(1)<CR><C-T>":"<Tab>"
inoremap <buffer><silent>       <S-Tab> <C-O>:call <SID>MarkdownModifyBullet(-1)<CR><C-D>

inoremap <buffer> <CR> <C-O>:call <SID>MarkdownRemoveBullet()<CR><CR>

