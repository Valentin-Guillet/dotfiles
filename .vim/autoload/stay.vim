
runtime START autoload/stay.vim


""" Overwriting stay function, because I don't use hidden
function! stay#ispersistent(bufnr, volatile_ftypes) abort
    let l:bufpath = expand('#'.a:bufnr.':p') " empty on invalid buffer numbers
    return
        \ !empty(l:bufpath) &&
        \ getbufvar(a:bufnr, 'stay_ignore') isnot 1 &&
        \ getbufvar(a:bufnr, '&buflisted') is 1 &&
        \ index(['', 'acwrite'], getbufvar(a:bufnr, '&buftype')) isnot -1 &&
        \ filereadable(l:bufpath) &&
        \ stay#isftype(a:bufnr, a:volatile_ftypes) isnot 1 &&
        \ stay#istemp(l:bufpath) isnot 1
endfunction
