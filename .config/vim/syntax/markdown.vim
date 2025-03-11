" Vim syntax file
" Language:	Markdown
" Maintainer:	Ben Williams <benw@plasticboy.com>
" URL:    http://plasticboy.com/markdown-vim-mode/
" Remark:	Uses HTML syntax file
" TODO:   Handle stuff contained within stuff (e.g. headings within blockquotes)


if exists("b:current_syntax")
  finish
endif

" Read the HTML syntax to start with
runtime! syntax/html.vim

syn spell toplevel
syn case ignore
syn sync linebreaks=1

syn clear htmlError

let s:conceal = ''
let s:concealends = ''
let s:concealcode = ''
if has('conceal') && get(g:, 'vim_markdown_conceal', 1)
  let s:conceal = ' conceal'
  let s:concealends = ' concealends'
endif
if has('conceal') && get(g:, 'vim_markdown_conceal_code_blocks', 1)
  let s:concealcode = ' concealends'
endif

" additions to HTML groups
if get(g:, 'vim_markdown_emphasis_multiline', 1)
    let s:oneline = ''
else
    let s:oneline = ' oneline'
endif
syn region mkdUnderline matchgroup=mkdUnderline start="\%(\*\|_\)"    end="\%(\*\|_\)"
syn region mkdBold matchgroup=mkdBold start="\%(\*\*\|__\)"    end="\%(\*\*\|__\)"
syn region mkdBoldUnderline matchgroup=mkdBoldUnderline start="\%(\*\*\*\|___\)"    end="\%(\*\*\*\|___\)"
execute 'syn region htmlUnderline matchgroup=mkdUnderline start="\%(^\|\s\)\zs\*\ze[^\\\*\t ]\%(\%([^*]\|\\\*\|\n\)*[^\\\*\t ]\)\?\*\_W" end="[^\\\*\t ]\zs\*\ze\_W" keepend contains=@Spell' . s:oneline . s:concealends
execute 'syn region htmlUnderline matchgroup=mkdUnderline start="\%(^\|\s\)\zs_\ze[^\\_\t ]" end="[^\\_\t ]\zs_\ze\_W" keepend contains=@Spell' . s:oneline . s:concealends
execute 'syn region htmlBold matchgroup=mkdBold start="\%(^\|\s\)\zs\*\*\ze\S" end="\S\zs\*\*" keepend contains=@Spell' . s:oneline . s:concealends
execute 'syn region htmlBold matchgroup=mkdBold start="\%(^\|\s\)\zs__\ze\S" end="\S\zs__" keepend contains=@Spell' . s:oneline . s:concealends
execute 'syn region htmlBoldUnderline matchgroup=mkdBoldUnderline start="\%(^\|\s\)\zs\*\*\*\ze\S" end="\S\zs\*\*\*" keepend contains=@Spell' . s:oneline . s:concealends
execute 'syn region htmlBoldUnderline matchgroup=mkdBoldUnderline start="\%(^\|\s\)\zs___\ze\S" end="\S\zs___" keepend contains=@Spell' . s:oneline . s:concealends

" [link](URL) | [link][id] | [link][] | ![image](URL)
syn region mkdFootnotes matchgroup=mkdDelimiter start="\[^"    end="\]"
syn match mkdLinkAcronyms /\<\(\u\|\d\)\{3,}s\?\>/ contained contains=@NoSpell
execute 'syn region mkdID matchgroup=mkdDelimiter    start="\["    end="\]" contained oneline' . s:conceal
execute 'syn region mkdURL matchgroup=mkdDelimiter   start="("     end=")"  contained oneline' . s:conceal
execute 'syn region mkdLink matchgroup=mkdDelimiter  start="\\\@<!!\?\[\ze[^]\n]*\n\?[^]\n]*\][[(]" end="\]" contains=mkdLinkAcronyms,@mkdNonListItem,@Spell nextgroup=mkdURL,mkdID skipwhite' . s:concealends

" Autolink without angle brackets.
" mkd  inline links:      protocol     optional  user:pass@  sub/domain                    .com, .co.uk, etc         optional port   path/querystring/hash fragment
"                         ------------ _____________________ ----------------------------- _________________________ ----------------- __
syn match   mkdInlineURL /https\?:\/\/\(\w\+\(:\w\+\)\?@\)\?\([A-Za-z0-9][-_0-9A-Za-z]*\.\)\{1,}\(\w\{2,}\.\?\)\{1,}\(:[0-9]\{1,5}\)\?\S*/

" Autolink with parenthesis.
syn region  mkdInlineURL matchgroup=mkdDelimiter start="(\(https\?:\/\/\(\w\+\(:\w\+\)\?@\)\?\([A-Za-z0-9][-_0-9A-Za-z]*\.\)\{1,}\(\w\{2,}\.\?\)\{1,}\(:[0-9]\{1,5}\)\?\S*)\)\@=" end=")"

" Autolink with angle brackets.
syn region mkdInlineURL matchgroup=mkdDelimiter start="\\\@<!<\ze[a-z][a-z0-9,.-]\{1,22}:\/\/[^> ]*>" end=">"

" Link definitions: [id]: URL (Optional Title)
syn region mkdLinkDef matchgroup=mkdDelimiter   start="^ \{,3}\zs\[\^\@!" end="]:" oneline nextgroup=mkdLinkDefTarget skipwhite
syn region mkdLinkDefTarget start="<\?\zs\S" excludenl end="\ze[>[:space:]\n]"   contained nextgroup=mkdLinkTitle,mkdLinkDef skipwhite skipnl oneline
syn region mkdLinkTitle matchgroup=mkdDelimiter start=+"+     end=+"+  contained
syn region mkdLinkTitle matchgroup=mkdDelimiter start=+'+     end=+'+  contained
syn region mkdLinkTitle matchgroup=mkdDelimiter start=+(+     end=+)+  contained

"HTML headings
syn match mkdH1Acronyms /\<\(\u\|\d\)\{3,}s\?\>/ contained contains=@NoSpell
syn match mkdH2Acronyms /\<\(\u\|\d\)\{3,}s\?\>/ contained contains=@NoSpell
syn match mkdH3Acronyms /\<\(\u\|\d\)\{3,}s\?\>/ contained contains=@NoSpell
syn match mkdH4Acronyms /\<\(\u\|\d\)\{3,}s\?\>/ contained contains=@NoSpell
syn match mkdH5Acronyms /\<\(\u\|\d\)\{3,}s\?\>/ contained contains=@NoSpell
syn match mkdH6Acronyms /\<\(\u\|\d\)\{3,}s\?\>/ contained contains=@NoSpell
syn region htmlH1       matchgroup=mkdHeading     start="^\s*#"                   end="$" contains=mkdH1Acronyms,mkdLink,mkdInlineURL,@Spell
syn region htmlH2       matchgroup=mkdHeading     start="^\s*##"                  end="$" contains=mkdH2Acronyms,mkdLink,mkdInlineURL,@Spell
syn region htmlH3       matchgroup=mkdHeading     start="^\s*###"                 end="$" contains=mkdH3Acronyms,mkdLink,mkdInlineURL,@Spell
syn region htmlH4       matchgroup=mkdHeading     start="^\s*####"                end="$" contains=mkdH4Acronyms,mkdLink,mkdInlineURL,@Spell
syn region htmlH5       matchgroup=mkdHeading     start="^\s*#####"               end="$" contains=mkdH5Acronyms,mkdLink,mkdInlineURL,@Spell
syn region htmlH6       matchgroup=mkdHeading     start="^\s*######"              end="$" contains=mkdH6Acronyms,mkdLink,mkdInlineURL,@Spell
syn match  htmlH1       /^.\+\n=\+$/ contains=mkdLink,mkdInlineURL,@Spell
syn match  htmlH2       /^.\+\n-\+$/ contains=mkdLink,mkdInlineURL,@Spell

"define Markdown groups
syn match  mkdLineBreak    /  \+$/
syn region mkdBlockquote   start=/^\s*>/                   end=/$/ contains=mkdLink,mkdInlineURL,mkdLineBreak,@Spell
execute 'syn region mkdCode matchgroup=mkdCodeDelimiter start=/\(\([^\\]\|^\)\\\)\@<!`/                     end=/`/'  . s:concealcode
execute 'syn region mkdCode matchgroup=mkdCodeDelimiter start=/\(\([^\\]\|^\)\\\)\@<!``/ skip=/[^`]`[^`]/   end=/``/' . s:concealcode
execute 'syn region mkdCode matchgroup=mkdCodeDelimiter start=/^\s*\z(`\{3,}\)[^`]*$/                       end=/^\s*\z1`*\s*$/'            . s:concealcode
execute 'syn region mkdCode matchgroup=mkdCodeDelimiter start=/\(\([^\\]\|^\)\\\)\@<!\~\~/  end=/\(\([^\\]\|^\)\\\)\@<!\~\~/'               . s:concealcode
execute 'syn region mkdCode matchgroup=mkdCodeDelimiter start=/^\s*\z(\~\{3,}\)\s*[0-9A-Za-z_+-]*\s*$/      end=/^\s*\z1\~*\s*$/'           . s:concealcode
execute 'syn region mkdCode matchgroup=mkdCodeDelimiter start="<pre[^>]*\\\@<!>"                            end="</pre>"'                   . s:concealcode
execute 'syn region mkdCode matchgroup=mkdCodeDelimiter start="<code[^>]*\\\@<!>"                           end="</code>"'                  . s:concealcode
syn region mkdFootnote     start="\[^"                     end="\]"
syn match  mkdCode         /^\s*\n\(\(\s\{8,}[^ ]\|\t\t\+[^\t]\).*\n\)\+/
syn match  mkdCode         /\%^\(\(\s\{4,}[^ ]\|\t\+[^\t]\).*\n\)\+/
syn match  mkdCode         /^\s*\n\(\(\s\{4,}[^ ]\|\t\+[^\t]\).*\n\)\+/ contained
syn match  mkdListItem     /^\s*\%([-+*.|]\|\d\+\.\)\ze\s\+/ contained
syn match  mkdTodoItem     /^\s*\%([-+*.|]\|\d\+\.\)\s\+\[.\]/ contained
syn match  mkdTodoItemDone /^\s*\%([-+*.|]\|\d\+\.\)\s\+\[X\].*/ contained contains=@mkdNonListItem
syn match  mkdArrows       /[-=]>/ contained
syn match  mkdAcronyms     /\<\(\u\|\d\)\{3,}s\?\>/ contained contains=@NoSpell
syn region mkdListItemLine start="^\s*\%([-+*.|]\|\d\+\.\)\s\+" end="$" oneline contains=@mkdNonListItem,mkdListItem,mkdTodoItem,mkdTodoItemDone,mkdArrows,mkdAcronyms,@Spell
syn region mkdNonListItemBlock start="\(^\(\s*\([-+*.|]\|\d\+\.\)\s\+\)\@!\|\n\(\_^\_$\|\s\{4,}[^ ]\|\t+[^\t]\)\@!\)" end="^\(\s*\([-+*.|]\|\d\+\.\)\s\+\)\@=" contains=@mkdNonListItem,mkdArrows,mkdAcronyms,@Spell
syn match  mkdRule         /^\s*\*\s\{0,1}\*\s\{0,1}\*\(\*\|\s\)*$/
syn match  mkdRule         /^\s*-\s\{0,1}-\s\{0,1}-\(-\|\s\)*$/
syn match  mkdRule         /^\s*_\s\{0,1}_\s\{0,1}_\(_\|\s\)*$/

" YAML frontmatter
if get(g:, 'vim_markdown_frontmatter', 0)
  syn include @yamlTop syntax/yaml.vim
  syn region Comment matchgroup=mkdDelimiter start="\%^---$" end="^\(---\|\.\.\.\)$" contains=@yamlTop keepend
  unlet! b:current_syntax
endif

if get(g:, 'vim_markdown_toml_frontmatter', 0)
  try
    syn include @tomlTop syntax/toml.vim
    syn region Comment matchgroup=mkdDelimiter start="\%^+++$" end="^+++$" transparent contains=@tomlTop keepend
    unlet! b:current_syntax
  catch /E484/
    syn region Comment matchgroup=mkdDelimiter start="\%^+++$" end="^+++$"
  endtry
endif

if get(g:, 'vim_markdown_json_frontmatter', 0)
  try
    syn include @jsonTop syntax/json.vim
    syn region Comment matchgroup=mkdDelimiter start="\%^{$" end="^}$" contains=@jsonTop keepend
    unlet! b:current_syntax
  catch /E484/
    syn region Comment matchgroup=mkdDelimiter start="\%^{$" end="^}$"
  endtry
endif

if get(g:, 'vim_markdown_math', 0)
  syn include @tex syntax/tex.vim
  syn region mkdMath start="\\\@<!\$" end="\$" skip="\\\$" contains=@tex keepend
  syn region mkdMath start="\\\@<!\$\$" end="\$\$" skip="\\\$" contains=@tex keepend
endif

" Strike through
if get(g:, 'vim_markdown_strikethrough', 0)
    execute 'syn region mkdStrike matchgroup=htmlStrike start="\%(\~\~\)" end="\%(\~\~\)"' . s:concealends
    hi def link mkdStrike        htmlStrike
endif

syn cluster mkdNonListItem contains=@htmlTop,htmlUnderline,htmlBold,htmlBoldUnderline,mkdFootnotes,mkdInlineURL,mkdLink,mkdLinkDef,mkdLineBreak,mkdBlockquote,mkdCode,mkdRule,htmlH1,htmlH2,htmlH3,htmlH4,htmlH5,htmlH6,mkdMath,mkdStrike

syn clear htmlTag

"highlighting for Markdown groups
hi def link mkdString        String
hi def link mkdCode          String
hi def link mkdCodeDelimiter String
hi def link mkdCodeStart     String
hi def link mkdCodeEnd       String
hi def link mkdFootnote      Comment
hi def link mkdBlockquote    Comment
hi def link mkdListItem      Identifier
hi def link mkdTodoItem      Identifier
hi def link mkdTodoItemDone  Comment
hi def link mkdRule          Identifier
hi def link mkdLineBreak     Visual
hi def link mkdFootnotes     htmlLink
hi def link mkdLinkAcronyms  htmlLink
hi def link mkdLink          htmlLink
hi def link mkdURL           htmlString
hi def link mkdInlineURL     htmlLink
hi def link mkdID            Identifier
hi def link mkdLinkDef       mkdID
hi def link mkdLinkDefTarget mkdURL
hi def link mkdLinkTitle     htmlString
hi def link mkdDelimiter     Delimiter
hi def link mkdArrows        htmlTag
hi def link mkdH1Acronyms    htmlH1
hi def link mkdH2Acronyms    htmlH2
hi def link mkdH3Acronyms    htmlH3
hi def link mkdH4Acronyms    htmlH4
hi def link mkdH5Acronyms    htmlH5
hi def link mkdH6Acronyms    htmlH6

hi htmlH1 term=bold ctermfg=124
hi htmlH2 term=bold ctermfg=166
hi htmlH3 term=bold ctermfg=125

let b:current_syntax = "mkd"

" vim: ts=2:sw=2:tw=0
