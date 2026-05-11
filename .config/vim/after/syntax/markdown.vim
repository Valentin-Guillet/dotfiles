scriptencoding utf-8

" Compute conceal option (script-local copy needed since remote's is s:-scoped)
let s:concealends = ''
if has('conceal') && get(g:, 'vim_markdown_conceal', 1)
    let s:concealends = ' concealends'
endif

" Clear htmlError — we don't want HTML-error highlighting inside markdown
syntax clear htmlError

" Remove distracting HTML-tag highlighting in markdown buffers
syntax clear htmlTag

" --- Acronym support in links ---
syntax match mkdLinkAcronyms /\<\(\u\|\d\)\{3,}s\?\>/ contained contains=@NoSpell

" Override mkdLink so acronyms inside link text are not spell-checked
execute 'syntax region mkdLink matchgroup=mkdDelimiter'
    \ . ' start="\\\@<!!\?\[\ze[^]\n]*\n\?[^]\n]*\][[(]" end="\]"'
    \ . ' contains=mkdLinkAcronyms,@mkdNonListItem,@Spell'
    \ . ' nextgroup=mkdURL,mkdID skipwhite' . s:concealends

" --- Per-heading-level acronyms (keeps them from being spell-checked) ---
syntax match mkdH1Acronyms /\<\(\u\|\d\)\{3,}s\?\>/ contained contains=@NoSpell
syntax match mkdH2Acronyms /\<\(\u\|\d\)\{3,}s\?\>/ contained contains=@NoSpell
syntax match mkdH3Acronyms /\<\(\u\|\d\)\{3,}s\?\>/ contained contains=@NoSpell
syntax match mkdH4Acronyms /\<\(\u\|\d\)\{3,}s\?\>/ contained contains=@NoSpell
syntax match mkdH5Acronyms /\<\(\u\|\d\)\{3,}s\?\>/ contained contains=@NoSpell
syntax match mkdH6Acronyms /\<\(\u\|\d\)\{3,}s\?\>/ contained contains=@NoSpell

" Override heading syntax with simplified contains (drop @mkdHeadingContent cluster)
syntax region htmlH1 matchgroup=mkdHeading start="^\s*#"      end="$" contains=mkdH1Acronyms,mkdLink,mkdInlineURL,@Spell
syntax region htmlH2 matchgroup=mkdHeading start="^\s*##"     end="$" contains=mkdH2Acronyms,mkdLink,mkdInlineURL,@Spell
syntax region htmlH3 matchgroup=mkdHeading start="^\s*###"    end="$" contains=mkdH3Acronyms,mkdLink,mkdInlineURL,@Spell
syntax region htmlH4 matchgroup=mkdHeading start="^\s*####"   end="$" contains=mkdH4Acronyms,mkdLink,mkdInlineURL,@Spell
syntax region htmlH5 matchgroup=mkdHeading start="^\s*#####"  end="$" contains=mkdH5Acronyms,mkdLink,mkdInlineURL,@Spell
syntax region htmlH6 matchgroup=mkdHeading start="^\s*######" end="$" contains=mkdH6Acronyms,mkdLink,mkdInlineURL,@Spell
syntax match  htmlH1 /^.\+\n=\+$/ contains=mkdLink,mkdInlineURL,@Spell
syntax match  htmlH2 /^.\+\n-\+$/ contains=mkdLink,mkdInlineURL,@Spell

" --- Extended list / todo syntax ---
" Clear old list definitions so our replacements take full effect
silent! syntax clear mkdListItem
silent! syntax clear mkdListItemCheckbox
silent! syntax clear mkdListItemLine
silent! syntax clear mkdNonListItemBlock

" List bullets now include '.' and '|' in addition to the standard -/+/*
syntax match  mkdListItem     /^\s*\%([-+*.|]\|\d\+\.\)\ze\s\+/ contained
syntax match  mkdTodoItem     /^\s*\%([-+*.|]\|\d\+\.\)\s\+\[.\]/  contained
syntax match  mkdTodoItemDone /^\s*\%([-+*.|]\|\d\+\.\)\s\+\[X\].*/ contained contains=@mkdNonListItem
syntax match  mkdArrows       /[-=]>/ contained
syntax match  mkdAcronyms     /\<\(\u\|\d\)\{3,}s\?\>/ contained contains=@NoSpell

syntax region mkdListItemLine start="^\s*\%([-+*.|]\|\d\+\.\)\s\+" end="$" oneline
    \ contains=@mkdNonListItem,mkdListItem,mkdTodoItem,mkdTodoItemDone,mkdArrows,mkdAcronyms,@Spell

syntax region mkdNonListItemBlock
    \ start="\(^\(\s*\([-+*.|]\|\d\+\.\)\s\+\)\@!\|\n\(\_^\_$\|\s\{4,}[^ ]\|\t+[^\t]\)\@!\)"
    \ end="^\(\s*\([-+*.|]\|\d\+\.\)\s\+\)\@="
    \ contains=@mkdNonListItem,mkdArrows,mkdAcronyms,@Spell

" --- Highlight links ---
highlight default link mkdTodoItem      Identifier
highlight default link mkdTodoItemDone  Comment
highlight default link mkdLinkAcronyms  htmlLink
highlight default link mkdArrows        htmlTag
highlight default link mkdH1Acronyms    htmlH1
highlight default link mkdH2Acronyms    htmlH2
highlight default link mkdH3Acronyms    htmlH3
highlight default link mkdH4Acronyms    htmlH4
highlight default link mkdH5Acronyms    htmlH5
highlight default link mkdH6Acronyms    htmlH6

" Explicit header colours
hi htmlH1 term=bold ctermfg=124
hi htmlH2 term=bold ctermfg=166
hi htmlH3 term=bold ctermfg=125

" vim: ts=2:sw=2:tw=0
