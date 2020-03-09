
if exists('b:current_syntax')
  finish
endif

syn match tocH1 '[^ ].*'
syn match tocH2 '  [^ ].*'
syn match tocH3 '    [^ ].*'
syn match tocH4 '      [^ ].*'

let b:current_syntax = "toc"
hi def link tocH1 htmlH1
hi def link tocH2 htmlH2
hi def link tocH3 htmlH3
hi def link tocH4 htmlH4

" vim: ts=2:sw=2
