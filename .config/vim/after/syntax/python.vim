
syntax keyword pythonDefinition  lambda
syntax keyword pythonDefinition  def nextgroup=pythonFunction skipwhite
syntax keyword pythonDefinition  class nextgroup=pythonClass skipwhite
syntax match   pythonDefinition  '\<async\s\+def\>' nextgroup=pythonFunction skipwhite

highlight pythonFunctionCall     ctermfg=81
highlight pythonDefinition       ctermfg=81
highlight pythonDottedName       ctermfg=81
highlight pythonDecorator        ctermfg=161
highlight pythonClass            ctermfg=118
highlight link pythonBuiltinFunc pythonFunctionCall
highlight link pythonBytesEscape pythonNumber
highlight link pythonRun         Comment
