
function! man#goto_section(direction, mode, count)
    norm! m'
    if a:mode ==# 'v'
        norm! gv
    endif
    let i = 0
    while i < a:count
        let i += 1
        " saving current position
        let line = line('.')
        let col  = col('.')
        let pos = search('^\a\+', 'W'.a:direction)
        " if there are no more matches, return to last position
        if pos == 0
            call cursor(line, col)
            return
        endif
    endwhile
endfunction

function! man#resize_win()
    let l:prev_line = line('.')
    let l:prev_nb_lines = line('$')

    call cursor(1, 1)
    call dist#man#PreGetPage(0)

    let l:nb_lines = line('$')
    let l:target_line = l:prev_line * l:nb_lines / l:prev_nb_lines
    if l:prev_nb_lines > l:nb_lines | let l:target_line += 1 | endif
    call cursor(l:target_line, 1)
    normal! ^
endfunction

function! man#goto_link(count)
    let l:output = execute("call dist#man#PreGetPage(a:count)")[1:]

    " Output other than page not found
    if l:output !~ '^man.vim: no manual entry for'
        echomsg l:output
        return
    endif

    " Not on an uppercase word
    if expand("<cword>") !~ '^\u\+$'
        echomsg l:output
        return
    endif

    " Get uppercase words around the cursor
    let l:upper_regex = '\%( \u\+\)* \?\u*\%.c\u* \?\%(\u\+ \)*'
    let l:upper_words = trim(matchstr(getline('.'), l:upper_regex))

    " If uppercase word does not correspond to a subsection
    if search('^' . l:upper_words, 'ws') == 0
        echomsg l:output
    endif

endfunction


" Man command completion from "vim-utils/vim-man
function! man#complete(A, L, P)
    let manpath = s:get_manpath()
    if manpath =~# '^\s*$'
        return []
    endif
    let section = s:get_manpage_section(a:L, a:P)
    let path_glob = s:get_path_glob(manpath, section, '', ',')
    let matching_files = s:expand_path_glob(path_glob, a:A)
    return s:strip_file_names(matching_files)
endfunction

" extracts the manpage section number (if there is one) from the command
function! s:get_manpage_section(line, cursor_position)
    " extracting section argument from the line
    let leading_line = strpart(a:line, 0, a:cursor_position)
    let section_arg = matchstr(leading_line, '^\s*\S\+\s\+\zs\S\+\ze\s\+')
    if !empty(section_arg)
        return s:extract_permitted_section_value(section_arg)
    endif
    " no section arg or extracted section cannot be used for man dir name globbing
    return ''
endfunction

" strips file names so they correspond manpage names
function! s:strip_file_names(matching_files)
    if empty(a:matching_files)
        return []
    else
        let matches = []
        let len = 0
        for manpage_path in a:matching_files
            " since already looping also count list length
            let len += 1
            let manpage_name = substitute(fnamemodify(manpage_path, ':t'), '\.\(\d\a*\|n\|ntcl\)\(\.\a*\|\.bz2\)\?$', '', '')
            call add(matches, manpage_name)
        endfor
        " remove duplicates from small lists (it takes noticeably longer
        " and is less relevant for large lists)
        return len > 500 ? matches : filter(matches, 'index(matches, v:val, v:key+1)==-1')
    endif
endfunction

function! s:get_manpath()
    " We don't expect manpath to change, so after first invocation it's
    " saved/cached in a script variable to speed things up on later invocations.
    if !exists('s:manpath')
        " perform a series of commands until manpath is found
        let s:manpath = $MANPATH
        if s:manpath ==# ''
            let s:manpath = system('manpath 2>/dev/null')
            if s:manpath ==# ''
                let s:manpath = system('man -w 2>/dev/null')
            endif
        endif
        " strip trailing newline for output from the shell
        let s:manpath = substitute(s:manpath, '\n$', '', '')
    endif
    return s:manpath
endfunction

function! s:get_path_glob(manpath, section, file, separator)
    let section_part = empty(a:section) ? '*' : a:section
    let file_part = empty(a:file) ? '' : a:file
    let man_globs = substitute(a:manpath.':', ':', '/*man'.section_part.'/'.file_part.a:separator, 'g')
    let cat_globs = substitute(a:manpath.':', ':', '/*cat'.section_part.'/'.file_part.a:separator, 'g')
    " remove one unecessary path separator from the end
    let cat_globs = substitute(cat_globs, a:separator.'$', '', '')
    return man_globs.cat_globs
endfunction

function! s:expand_path_glob(path_glob, manpage_prefix)
    if empty(a:manpage_prefix)
        let manpage_part = '*'
    elseif a:manpage_prefix =~# '*$'
        " asterisk is already present
        let manpage_part = a:manpage_prefix
    else
        let manpage_part = a:manpage_prefix.'*'
    endif
    return split(globpath(a:path_glob, manpage_part, 1), '\n')
endfunction

function! s:extract_permitted_section_value(section_arg)
    if a:section_arg =~# '^*$'
        " matches all dirs with a glob 'man*'
        return a:section_arg
    elseif a:section_arg =~# '^\d[xp]\?$'
        " matches dirs: man1, man1x, man1p
        return a:section_arg
    elseif a:section_arg =~# '^[nlpo]$'
        " matches dirs: mann, manl, manp, mano
        return a:section_arg
    elseif a:section_arg =~# '^\d\a\+$'
        " take only first digit, sections 3pm, 3ssl, 3tiff, 3tcl are searched in man3
        return matchstr(a:section_arg, '^\d')
    else
        return ''
    endif
endfunction
