
syntax keyword pythonDefinition  lambda
syntax keyword pythonDefinition  def nextgroup=pythonFunction skipwhite
syntax keyword pythonDefinition  class nextgroup=pythonClass skipwhite
syntax match   pythonDefinition  '\<async\s\+def\>' nextgroup=pythonFunction skipwhite

highlight pythonFunctionCall     guifg=#5fd7ff ctermfg=81
highlight pythonDefinition       guifg=#5fd7ff ctermfg=81
highlight pythonDottedName       guifg=#5fd7ff ctermfg=81
highlight pythonDecorator        guifg=#d7005f ctermfg=161
highlight pythonClass            guifg=#87ff00 ctermfg=118
highlight link pythonBuiltinFunc pythonFunctionCall
highlight link pythonBytesEscape pythonNumber
highlight link pythonRun         Comment
