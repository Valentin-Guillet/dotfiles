
syn keyword pythonDefinition     lambda
syn keyword pythonDefinition     def nextgroup=pythonFunction skipwhite
syn match   pythonDefinition     '\<async\s\+def\>' nextgroup=pythonFunction skipwhite
syn keyword pythonDefinition     class nextgroup=pythonClass skipwhite
