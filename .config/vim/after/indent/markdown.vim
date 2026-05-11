scriptencoding utf-8

" Patch for indent/markdown.vim:
"   1. Don't auto-insert bullets for .todo / ToDo files (todo mode handles
"      its own newline logic).
"   2. Accept '.' and '|' as bullet comment leaders.
"   3. Fix GetMarkdownIndent() to return 0 (not ind+list_ind) after a list
"      item, so <CR> in a list does not over-indent the next line.

" Undo the bullet comment-leaders the remote indent file added for non-todo
" files, then re-add our extended set.  For todo files, we add nothing here;
" SetTodoMode() in after/ftplugin will handle formatoptions/comments.
if get(g:, 'vim_markdown_auto_insert_bullets', 1)
    if expand('%:t') =~# '.*\.todo' || expand('%:t') ==# 'ToDo'
        " Undo what the remote indent file set for this buffer
        setlocal formatoptions+=c
        setlocal comments-=b:*,b:+,b:-
    else
        " Add '.' and '|' to the accepted bullet leaders
        setlocal comments+=b:.,b:\|
    endif
endif

" Override GetMarkdownIndent so that pressing <CR> after a list-item line
" does NOT blindly indent by list_ind – our bullet/todo machinery handles
" indentation explicitly.
function! s:IsMkdCode(lnum)
    let name = synIDattr(synID(a:lnum, 1, 0), 'name')
    return (name =~ '^mkd\%(Code$\|Snippet\)' || name != '' && name !~ '^\%(mkd\|html\)')
endfunction

function! s:IsLiStart(line)
    return a:line !~ '^ *\([*-]\)\%( *\1\)\{2}\%( \|\1\)*$' &&
      \    a:line =~ '^\s*[*+-] \+'
endfunction

function! s:IsHeaderLine(line)
    return a:line =~ '^\s*#'
endfunction

function! s:IsBlankLine(line)
    return a:line =~ '^$'
endfunction

function! s:PrevNonBlank(lnum)
    let i = a:lnum
    while i > 1 && s:IsBlankLine(getline(i))
        let i -= 1
    endwhile
    return i
endfunction

function! GetMarkdownIndent()
    if v:lnum > 2 && getline(v:lnum - 1) =~# '^$' && getline(v:lnum - 2) =~# '^$'
        return 0
    endif
    " Find a non-blank line above the current line.
    let l:lnum = s:PrevNonBlank(v:lnum - 1)
    if l:lnum == 0 | return 0 | endif

    let l:ind   = indent(l:lnum)
    let l:line  = getline(l:lnum)
    let l:cline = getline(v:lnum)

    if s:IsLiStart(l:cline)
        return indent(v:lnum)
    elseif s:IsHeaderLine(l:cline) && !s:IsMkdCode(v:lnum)
        return 0
    elseif s:IsLiStart(l:line)
        " Previous line started a list item — do NOT auto-indent the next line
        " (the todo/bullet machinery creates the right prefix itself).
        return s:IsMkdCode(l:lnum) ? l:ind : 0
    else
        return l:ind
    endif
endfunction
