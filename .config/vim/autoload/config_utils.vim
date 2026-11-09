
function! config_utils#translate_path(path)
    if !has("win32")
        return a:path
    else
        return substitute(a:path, "/", '\\\\', "g")
    endif
endfunction

