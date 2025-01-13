
function format_diff#FormatCpp(file_path) abort
    " No fixes to apply
    silent execute "!clang-format --dry-run -Werror 2> /dev/null " . a:file_path
    if v:shell_error == 0 | return 0 | endif

    silent execute "!clang-format -i " . a:file_path
    return 1
endfunction


function format_diff#FormatPython(file_path) abort
    " No fixes to apply
    silent execute "!ruff check " . a:file_path . " | grep -q 'fixable with the `--fix` option'"
    if v:shell_error == 1 | return 0 | endif

    silent execute "!ruff check --silent --fix " . a:file_path
    return 1
endfunction

function format_diff#FormatRust(file_path) abort
    " No fixes to apply
    silent execute "!rustfmt --check " . a:file_path
    if v:shell_error == 0 | return 0 | endif

    silent execute "!rustfmt --quiet " . a:file_path
    return 1
endfunction
