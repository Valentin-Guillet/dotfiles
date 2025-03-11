
if exists('b:current_syntax')
  finish
endif

syntax match tocH1 '[^ ].*'
syntax match tocH2 '  [^ ].*'
syntax match tocH3 '    [^ ].*'
syntax match tocH4 '      [^ ].*'

highlight def link tocH1 htmlH1
highlight def link tocH2 htmlH2
highlight def link tocH3 htmlH3
highlight def link tocH4 htmlH4

let b:current_syntax = "toc"

" vim: ts=2:sw=2
