" This plugin defines the 'FormatDiff' command that apply a formatting tool to
" the current file and opens a diff of the current version of the file and the
" formatted version.
"
" The formatting tool are defined in the file "autoload/format_diff.vim": to
" add a new filetype, create a vimscript function that takes a filepath as
" argument, that formats it and that returns whether any modification has been
" done.

if exists("g:loaded_format_diff")
    finish
endif
let g:loaded_format_diff = 1


function s:FormatDiff()
    if empty(&filetype)
        return
    endif

    let l:ft = &filetype
    let l:ft_title = toupper(l:ft[0]) . l:ft[1:]

    runtime autoload/format_diff.vim
    let l:fun_name = "format_diff#Format" . l:ft_title
    if !exists("*" . l:fun_name)
        echohl ErrorMsg | echo "No diff formatter found for filetype " . l:ft | echohl None
        return
    endif

    let l:file_path = tempname()
    silent execute "write " . l:file_path

    execute "let l:has_diffs = " . l:fun_name . '("' . l:file_path . '")'
    if l:has_diffs == 0
        silent call delete(l:file_path)
        redraw!
        echo "Diff is empty !"
        return
    endif

    " If more than one split, open in a new tab
    if tabpagewinnr('.', '$') > 1
        tab split
    endif
    vsplit | enew

    silent execute "read " . l:file_path
    silent call delete(l:file_path)
    let &l:filetype = l:ft

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

command! -bar FormatDiff call <SID>FormatDiff()
nnoremap <silent> <leader>F :FormatDiff<CR>
