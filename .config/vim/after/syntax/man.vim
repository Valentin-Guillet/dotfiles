
" Extra syntax and highlighting from 'vim-utils/vim-man' package

syntax match manHeaderFile '\s\zs<\f\+\.h>\ze\(\W\|$\)'
syntax match manURL        `\v(((https?|ftp|gopher)://|(mailto|file|news):)[^' 	<>"]+|(www|web|w3)[a-z0-9_-]*\.[a-z0-9._-]+\.[^' 	<>"]+)[a-zA-Z0-9/]`
syntax match manEmail      '<\?[a-zA-Z0-9_.+-]\+@[a-zA-Z0-9-]\+\.[a-zA-Z0-9-.]\+>\?'
syntax match manHighlight  +`.\{-}''\?+

syntax match manFile       display '\s\zs\~\?\/[0-9A-Za-z_*/$.{}<>-]*' contained
syntax match manEnvVarFile display '\s\zs\$[0-9A-Za-z_{}]\+\/[0-9A-Za-z_*/$.{}<>-]*' contained
syntax region manFiles     start='^FILES'hs=s+5 end='^\u[A-Z ]*$'me=e-30 keepend contains=manReference,manSectionHeading,manHeaderFile,manURL,manEmail,manFile,manEnvVarFile

syntax match manEnvVar     display '\s\zs\(\u\|_\)\{3,}' contained
syntax region manFiles     start='^ENVIRONMENT'hs=s+11 end='^\u[A-Z ]*$'me=e-30 keepend contains=manReference,manSectionHeading,manHeaderFile,manURL,manEmail,manEnvVar

highlight link manHeaderFile      String
highlight link manURL             Underlined
highlight link manEmail           Underlined
highlight link manHighlight       Statement
highlight link manFile            String
highlight link manEnvVarFile      String
highlight link manEnvVar          String


" Syntax elements valid for manpages 2 & 3 only
if getline(1) =~ '^\(\f\|:\)\+([23][px]\?)'
  syntax match manCError           display '^\s\+\[E\(\u\|\d\)\+\]' contained
  syntax match manSignal           display '\C\<\zs\(SIG\|SIG_\|SA_\)\(\d\|\u\)\+\ze\(\W\|$\)'
  syntax region manSynopsis start='^\(LEGACY \)\?SYNOPSIS'hs=s+8 end='^\u[A-Z ]*$'me=e-30 keepend contains=manSectionHeading,@cCode,manCFuncDefinition,manHeaderFile
  syntax region manErrors   start='^ERRORS'hs=s+6 end='^\u[A-Z ]*$'me=e-30 keepend contains=manSignal,manReference,manSectionHeading,manHeaderFile,manCError
endif

highlight link manCError          Identifier
highlight link manSignal          Identifier


" Other modifications
syntax match manReference '\<\zs\(\f\|:\)\+(\([nlpo]\|\d[a-z]*\)\?)\ze\(\W\|$\)' contains=manFunctionName,manFunctionArgs
syntax match manFunctionName '\<\zs\(\f\|:\)\+' contained
syntax match manFunctionArgs '(\([nlpo]\|\d[a-z]*\)\?)' contained contains=manSymbols

syntax match manSymbols '[()[\]{}|&<>;]'
syntax match manHeader '\%1l.*' contains=manHeaderCmd,manHeaderPage,manHeaderTitle,manSymbols
syntax match manHeaderCmd '\S\+\ze(' contained
syntax match manHeaderPage '\(\d\+\)' contained
syntax match manHeaderTitle '\t[^\t]\+\t' contained

syntax match manHistory	"^[a-z].*last change.*$"


highlight link manSymbols Statement

highlight manHeaderTitle ctermfg=166
highlight manHeaderCmd ctermfg=135
highlight manHeaderPage ctermfg=226

highlight manSectionHeading ctermfg=208

highlight manOptionDesc ctermfg=149
highlight manLongOptionDesc ctermfg=149

highlight manFunctionName ctermfg=149
highlight manFunctionArgs ctermfg=135
