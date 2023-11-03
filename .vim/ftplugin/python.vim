
set foldmethod=indent
set foldlevel=999

abbrev <buffer> brekapoint breakpoint
abbrev <buffer> breakpoitn breakpoint
abbrev <buffer> brekapoitn breakpoint

set makeprg=ruff\ %

command! -buffer -bar RuffDiff call ftplugin#python#RuffDiff()
