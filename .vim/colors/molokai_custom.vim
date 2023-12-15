
runtime colors/molokai.vim

if &t_Co > 255
    hi PreProc     ctermfg=161   cterm=bold
    hi String      ctermfg=229
    hi Character   ctermfg=144
    hi link cppSTLnamespace NONE
endif
