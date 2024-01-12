
runtime colors/molokai.vim

if &t_Co > 255
    hi PreProc     ctermfg=161   cterm=bold
    hi String      ctermfg=228
    hi Character   ctermfg=144

    hi link cppSTLnamespace NONE

    hi link pythonBuiltinFunc     pythonFunctionCall
    hi link pythonBytesEscape     pythonNumber
    hi link pythonRun             Comment
    hi pythonFunctionCall     ctermfg=81
    hi pythonDefinition       ctermfg=81
    hi pythonDottedName       ctermfg=81
    hi pythonDecorator        ctermfg=161
    hi pythonClass            ctermfg=118
endif
