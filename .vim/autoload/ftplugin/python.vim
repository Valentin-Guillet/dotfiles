
" Diff a file with the version fixed by `ruff`
function ftplugin#python#RuffDiff() abort
    " If more than one split, open in a new tab
    if tabpagewinnr('.', '$') > 1
        tab split
    endif

    let l:file_path = tempname()
    silent execute "write " . l:file_path

    " No fixes to apply
    silent execute "!ruff check " . l:file_path . " | grep -q 'fixable with the `--fix` option'"
    if v:shell_error == 1
        silent call delete(l:file_path)
        redraw!
        echo "No possible fix"
        return
    endif

    silent execute "!ruff check --silent --fix " . l:file_path
    vsplit | enew
    silent execute "read " . l:file_path
    silent call delete(l:file_path)
    setlocal filetype=python

    " Use feedkeys instead of plain `:q` because it doesn't work when multiple
    " tabs are open (cf. https://groups.google.com/g/vim_dev/c/Cw8McBH6DDM)
    autocmd WinEnter <buffer> if winnr('$') == 1 | call feedkeys(":q\<CR>") | endif

    normal ggdd
    setlocal buftype=nofile
    setlocal bufhidden=delete
    setlocal nobuflisted
    setlocal noswapfile
    setlocal nomodifiable
    setlocal readonly
    setlocal nomodified

    diffthis
    normal p
    diffthis
    normal gg]h
    redraw!
endfunction
