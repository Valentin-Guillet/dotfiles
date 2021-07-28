" Insert or delete brackets, parens, quotes in pairs.
" Maintainer:	JiangMiao <jiangfriend@gmail.com>
" Contributor: camthompson
" Last Change:  2019-02-02
" Version: 2.0.0
" Homepage: http://www.vim.org/scripts/script.php?script_id=3599
" Repository: https://github.com/jiangmiao/auto-pairs
" License: MIT

if exists('g:loaded_autopairs') || &cp
    finish
end
let g:loaded_autopairs = 1

if !exists('g:autopairs_pairs')
    let g:autopairs_pairs = {'(':')', '[':']', '{':'}',"'":"'",'"':'"', '```':'```', '"""':'"""', "'''":"'''", "`":"`"}
end

" default pairs base on filetype
func! s:AutoPairsDefaultPairs()
    if exists('b:autopairs_defaultpairs')
        return b:autopairs_defaultpairs
    end
    let r = copy(g:autopairs_pairs)
    let all_pairs = {
                \ 'rust': {'\w\zs<': '>', '&\zs''': ''},
                \ 'php': {'<?': '?>//k]', '<?php': '?>//k]'}
                \ }
    for [filetype, pairs] in items(all_pairs)
        if &filetype == filetype
            for [open, close] in items(pairs)
                let r[open] = close
            endfor
        end
    endfor
    let b:autopairs_defaultpairs = r
    return r
endf

if !exists('g:autopairs_map_BS')
    let g:autopairs_map_BS = 1
end

" Map <C-h> as the same BS
if !exists('g:autopairs_map_Ch')
    let g:autopairs_map_Ch = 1
end

if !exists('g:autopairs_map_CR')
    let g:autopairs_map_CR = 1
end

if !exists('g:autopairs_wild_closed_pair')
    let g:autopairs_wild_closed_pair = ''
end

if !exists('g:autopairs_map_space')
    let g:autopairs_map_space = 1
end

if !exists('g:autopairs_center_line')
    let g:autopairs_center_line = 1
end

if !exists('g:autopairs_shortcut_toggle')
    let g:autopairs_shortcut_toggle = '<M-p>'
end

if !exists('g:autopairs_shortcut_fast_wrap')
    let g:autopairs_shortcut_fast_wrap = '<M-e>'
end

if !exists('g:autopairs_shortcut_fast_unwrap')
    let g:autopairs_shortcut_fast_unwrap = '<M-r>'
end

if !exists('g:autopairs_move_character')
    let g:autopairs_move_character = "()[]{}\"'"
end

if !exists('g:autopairs_shortcut_jump')
    let g:autopairs_shortcut_jump = '<M-n>'
endif

" Fly mode will for closed pair to jump to closed pair instead of insert.
" also support autopairs_back_insert to insert pairs where jumped.
if !exists('g:autopairs_fly_mode')
    let g:autopairs_fly_mode = 0
endif

" When skipping the closed pair, look at the current and
" next line as well.
if !exists('g:autopairs_multiline_close')
    let g:autopairs_multiline_close = 1
endif

" Work with Fly Mode, insert pair where jumped
if !exists('g:autopairs_shortcut_back_insert')
    let g:autopairs_shortcut_back_insert = '<M-b>'
endif

if !exists('g:autopairs_smart_quotes')
    let g:autopairs_smart_quotes = 1
endif

" 7.4.849 support <C-G>U to avoid breaking '.'
" Issue talk: https://github.com/jiangmiao/auto-pairs/issues/3
" Vim note: https://github.com/vim/vim/releases/tag/v7.4.849
if v:version > 704 || v:version == 704 && has("patch849")
    let s:Go = "\<C-G>U"
else
    let s:Go = ""
endif

let s:Left = s:Go."\<LEFT>"
let s:Right = s:Go."\<RIGHT>"




" unicode len
func! s:ulen(s)
    return len(split(a:s, '\zs'))
endf

func! s:left(s)
    return repeat(s:Left, s:ulen(a:s))
endf

func! s:right(s)
    return repeat(s:Right, s:ulen(a:s))
endf

func! s:delete(s)
    return repeat("\<DEL>", s:ulen(a:s))
endf

func! s:backspace(s)
    return repeat("\<BS>", s:ulen(a:s))
endf

func! s:getline_before()
    let line = getline('.')
    let pos = col('.') - 1
    let before = strpart(line, 0, pos)
    let after = strpart(line, pos)
    if g:autopairs_multiline_close
        let i = line('.')-1
        while 0 <= i
            let line = getline(i)
            let before = line.' '.before
            if !(line =~ '\v^\s*$')
                break
            end
            let i = i-1
        endwhile
    end
    return [before, after]
endf

func! s:getline()
    let line = getline('.')
    let pos = col('.') - 1
    let before = strpart(line, 0, pos)
    let after = strpart(line, pos)
    let afterline = after
    if g:autopairs_multiline_close
        let n = line('$')
        let i = line('.')+1
        while i <= n
            let line = getline(i)
            let after = after.' '.line
            if !(line =~ '\v^\s*$')
                break
            end
            let i = i+1
        endwhile
    end
    return [before, after, afterline]
endf

" split text to two part
" returns [orig, text_before_open, open]
func! s:matchend(text, open)
    let m = matchstr(a:text, '\V'.a:open.'\v$')
    if m == ""
        return []
    end
    return [a:text, strpart(a:text, 0, len(a:text)-len(m)), m]
endf

" returns [orig, close, text_after_close]
func! s:matchbegin(text, close)
    let m = matchstr(a:text, '^\V'.a:close)
    if m == ""
        return []
    end
    return [a:text, m, strpart(a:text, len(m), len(a:text)-len(m))]
endf

" add or delete pairs base on g:AutoPairs
" AutoPairsDefine(addPairs:dict[, removeOpenPairList:list])
"
" eg:
"   au FileType html let b:AutoPairs = AutoPairsDefine({'<!--' : '-->'}, ['{'])
"   add <!-- --> pair and remove '{' for html file
func! AutoPairsDefine(pairs, ...)
    let r = s:AutoPairsDefaultPairs()
    if a:0 > 0
        for open in a:1
            unlet r[open]
        endfor
    end
    for [open, close] in items(a:pairs)
        let r[open] = close
    endfor
    return r
endf

func! s:AutoPairsInsert(key)
    if !b:autopairs_enabled
        return a:key
    end

    let b:autopairs_saved_pair = [a:key, getpos('.')]

    let [before, after, afterline] = s:getline()

    " Ignore auto close if prev character is \
    if before[-1:-1] == '\'
        return a:key
    end

    " check open pairs
    for [open, close, opt] in b:autopairs_list
        let ms = s:matchend(before.a:key, open)
        let m = matchstr(afterline, '^\v\s*\zs\V'.close)
        if len(ms) > 0
            " process the open pair

            " Don't insert pair of ' or " if there's an odd number on the line
            if (open == close || open == '\v(^|\W)\zs''') && (count(before, close) + count(afterline, close)) % 2
                return close
            endif

            " remove inserted pair
            " eg: if the pairs include < > and  <!-- -->
            " when <!-- is detected the inserted pair < > should be clean up
            let target = ms[1]
            let open_pair = ms[2]
            if len(open_pair) == 1 && m == open_pair
                break
            end
            let bs = ''
            let del = ''
            while len(before) > len(target)
                let found = 0
                " delete pair
                for [o, c, opt] in b:autopairs_list
                    let os = s:matchend(before, o)
                    if len(os) && len(os[1]) < len(target)
                        " any text before open_pair should not be deleted
                        continue
                    end
                    let cs = s:matchbegin(afterline, c)
                    if len(os) && len(cs)
                        let found = 1
                        let before = os[1]
                        let afterline = cs[2]
                        let bs = bs.s:backspace(os[2])
                        let del = del.s:delete(cs[1])
                        break
                    end
                endfor
                if !found
                    " delete charactor
                    let ms = s:matchend(before, '\v.')
                    if len(ms)
                        let before = ms[1]
                        let bs = bs.s:backspace(ms[2])
                    end
                end
            endwhile
            return bs.del.open_pair.close.s:left(close)
        end
    endfor

    " check close pairs
    for [open, close, opt] in b:autopairs_list
        if close == ''
            continue
        end
        if a:key == g:autopairs_wild_closed_pair || opt['mapclose'] && opt['key'] == a:key
            " the close pair is in the same line
            let m = matchstr(afterline, '^\v\s*\V'.close)
            if m != ''
                if before =~ '\V'.open.'\v\s*$' && m[0] =~ '\v\s'
                    " remove the space we inserted if the text in pairs is blank
                    return "\<DEL>".s:right(m[1:])
                else
                    return s:right(m)
                end
            end
            let m = matchstr(after, '^\v\s*\zs\V'.close)
            if m != ''
                if a:key == g:autopairs_wild_closed_pair || opt['multiline']
                    if b:autopairs_return_pos == line('.') && getline('.') =~ '\v^\s*$'
                        normal! ddk$
                    end
                    call search(m, 'We')
                    return "\<Right>"
                else
                    break
                end
            end
        end
    endfor


    " Fly Mode, and the key is closed-pairs, search closed-pair and jump
    if g:autopairs_fly_mode &&  a:key =~ '\v[\}\]\)]'
        if search(a:key, 'We')
            return "\<Right>"
        endif
    endif

    return a:key
endf

func! AutoPairsDelete()
    if !b:autopairs_enabled
        return "\<BS>"
    end

    let [before, after, ig] = s:getline()
    for [open, close, opt] in b:autopairs_list
        let b = matchstr(before, '\V'.open.'\v\s?$')
        let a = matchstr(after, '^\v\s*\V'.close)
        if b != '' && a != ''
            if b[-1:-1] == ' '
                if a[0] == ' '
                    return "\<BS>\<DELETE>"
                else
                    return "\<BS>"
                end
            end
            return s:backspace(b).s:delete(a)
        end
    endfor

    return "\<BS>"
    " delete the pair foo[]| <BS> to foo
    for [open, close, opt] in b:autopairs_list
        let m = s:matchend(before, '\V'.open.'\v\s*'.'\V'.close.'\v$')
        if len(m) > 0
            return s:backspace(m[2])
        end
    endfor
    return "\<BS>"
endf


" Fast wrap the word in brackets
func! s:AutoPairsFastWrap()
    let c = @"
    let col_before = col('.')
    normal! x
    let [before, after, ig] = s:getline()
    " Case when on last character of a line
    if g:autopairs_multiline_close && col('.') < col_before
        let after = after[2:]
    endif

    if after =~ '\v^\s?[{[(].*'
        normal! %p
    else
        for [open, close, opt] in b:autopairs_list
            if close == ''
                continue
            end
            if after =~ '^\s*\V'.open
                if after =~ '^\v\s+'
                    normal! w
                end
                call search(close, 'We')
                normal! p
                let @" = c
                return ""
            end
        endfor
        normal! ep
    end
    let @" = c
    return ""
endf


" Fast wrap the word in brackets
func! s:AutoPairsFastUnwrap()
    let c = @"
    let [before, after] = s:getline_before()
    normal! x
    if before =~ '\v[]})]\s?$'
        normal! h%gep
    else
        for [open, close, opt] in b:autopairs_list
            if close == ''
                continue
            end
            if before =~ '\V' . close . '\v\s*$'
                if col('.') != col('$')-1
                    normal! h
                end
                call search(open, 'bWe')
                normal! gep
                let @" = c
                return ""
            end
        endfor
        if before =~ '\v[{[(]$'
            normal! P
        else
            " Divide the command in two not to interrupt if h fails
            normal! h
            normal! gep
        endif
    end
    let @" = c
    return ""
endf


func! s:AutoPairsJump()
    call search('["\]'')}]','W')
endf

func! s:AutoPairsMoveCharacter(key)
    let c = getline(".")[col(".")-1]
    let escaped_key = substitute(a:key, "'", "''", 'g')
    return "\<DEL>\<ESC>:call search("."'".escaped_key."'".")\<CR>a".c."\<LEFT>"
endf

func! s:AutoPairsBackInsert()
    let pair = b:autopairs_saved_pair[0]
    let pos  = b:autopairs_saved_pair[1]
    call setpos('.', pos)
    return pair
endf

func! s:AutoPairsReturn()
    if b:autopairs_enabled == 0
        return ''
    end
    let b:autopairs_return_pos = 0
    let before = getline(line('.')-1)
    let [ig, ig, afterline] = s:getline()
    let cmd = ''
    for [open, close, opt] in b:autopairs_list
        if close == ''
            continue
        end

        if before =~ '\V'.open.'\v\s*$' && afterline =~ '^\s*\V'.close
            let b:autopairs_return_pos = line('.')
            if g:autopairs_center_line && winline() * 3 >= winheight(0) * 2
                " Recenter before adding new line to avoid replacing line content
                let cmd = "zz"
            end

            " If equalprg has been set, then avoid call =
            " https://github.com/jiangmiao/auto-pairs/issues/24
            if &equalprg != ''
                return "\<ESC>".cmd."O"
            endif

            " conflict with javascript and coffee
            " javascript   need   indent new line
            " coffeescript forbid indent new line
            if &filetype == 'coffeescript' || &filetype == 'coffee'
                return "\<ESC>".cmd."k==o"
            else
                return "\<ESC>".cmd."=ko"
            endif
        end
    endfor
    return ''
endf

func! s:AutoPairsSpace()
    if !b:autopairs_enabled
        return "\<SPACE>"
    end

    let [before, after, ig] = s:getline()

    for [open, close, opt] in b:autopairs_list
        if close == ''
            continue
        end
        if before =~ '\V'.open.'\v$' && after =~ '^\V'.close
            if close =~ '\v^[''"`]$'
                return "\<SPACE>"
            else
                return "\<SPACE>\<SPACE>".s:Left
            end
        end
    endfor
    return "\<SPACE>"
endf

func! s:AutoPairsMap(key)
    " | is special key which separate map command from text
    let key = a:key
    if key == '|'
        let key = '<BAR>'
    end
    let escaped_key = substitute(key, "'", "''", 'g')
    " use expr will cause search() doesn't work
    execute 'inoremap <buffer> <silent> '.key." <C-R>=<SID>AutoPairsInsert('".escaped_key."')<CR>"
endf

func! s:AutoPairsToggle()
    if b:autopairs_enabled
        let b:autopairs_enabled = 0
        echo 'Autopairs disabled'
    else
        let b:autopairs_enabled = 1
        echo 'Autopairs enabled'
    end
    return ''
endf

func! s:sortByLength(i1, i2)
    return len(a:i2[0])-len(a:i1[0])
endf

func! s:AutoPairsInit()
    let b:loaded_autopairs  = 1
    if !exists('b:autopairs_enabled')
        let b:autopairs_enabled = 1
    end

    if !exists('b:autopairs_pairs')
        let b:autopairs_pairs = s:AutoPairsDefaultPairs()
    end

    if !exists('b:autopairs_move_character')
        let b:autopairs_move_character = g:autopairs_move_character
    end

    let b:autopairs_return_pos = 0
    let b:autopairs_saved_pair = [0, 0]
    let b:autopairs_list = []

    " buffer level map pairs keys
    " n - do not map the first charactor of closed pair to close key
    " m - close key jumps through multi line
    " s - close key jumps only in the same line
    for [open, close] in items(b:autopairs_pairs)
        let o = open[-1:-1]
        let c = close[0]
        let opt = {'mapclose': 1, 'multiline':1}
        let opt['key'] = c
        if o == c
            let opt['multiline'] = 0
        end
        let m = matchlist(close, '\v(.*)//(.*)$')
        if len(m) > 0
            if m[2] =~ 'n'
                let opt['mapclose'] = 0
            end
            if m[2] =~ 'm'
                let opt['multiline'] = 1
            end
            if m[2] =~ 's'
                let opt['multiline'] = 0
            end
            let ks = matchlist(m[2], '\vk(.)')
            if len(ks) > 0
                let opt['key'] = ks[1]
                let c = opt['key']
            end
            let close = m[1]
        end
        call s:AutoPairsMap(o)
        if o != c && c != '' && opt['mapclose']
            call s:AutoPairsMap(c)
        end
        let b:autopairs_list += [[open, close, opt]]
    endfor

    " sort pairs by length, longer pair should have higher priority
    let b:autopairs_list = sort(b:autopairs_list, "s:sortByLength")

    for item in b:autopairs_list
        let [open, close, opt] = item
        if open == "'" && open == close
            let item[0] = '\v(^|\W)\zs'''
        end
    endfor


    for key in split(b:autopairs_move_character, '\s*')
        let escaped_key = substitute(key, "'", "''", 'g')
        execute 'inoremap <silent> <buffer> <M-'.key."> <C-R>=<SID>AutoPairsMoveCharacter('".escaped_key."')<CR>"
    endfor

    " Still use <buffer> level mapping for <BS> <SPACE>
    if g:autopairs_map_BS && get(b:, "autopairs_map_BS", 1)
        " Use <C-R> instead of <expr> for issue #14 sometimes press BS output strange words
        execute 'inoremap <buffer> <silent> <BS> <C-R>=AutoPairsDelete()<CR>'
    end

    if g:autopairs_map_Ch
        execute 'inoremap <buffer> <silent> <C-h> <C-R>=AutoPairsDelete()<CR><C-W>'
    endif

    if g:autopairs_map_space
        " Try to respect abbreviations on a <SPACE>
        let do_abbrev = ""
        if v:version == 703 && has("patch489") || v:version > 703
            let do_abbrev = "<C-]>"
        endif
        execute 'inoremap <buffer> <silent> <SPACE> '.do_abbrev.'<C-R>=<SID>AutoPairsSpace()<CR>'
    end

    if g:autopairs_shortcut_fast_wrap != ''
        execute 'inoremap <buffer> <silent> '.g:autopairs_shortcut_fast_wrap.' <C-R>=<SID>AutoPairsFastWrap()<CR>'
    end

    if g:autopairs_shortcut_fast_unwrap != ''
        execute 'inoremap <buffer> <silent> '.g:autopairs_shortcut_fast_unwrap.' <C-R>=<SID>AutoPairsFastUnwrap()<CR>'
    end

    if g:autopairs_shortcut_back_insert != ''
        execute 'inoremap <buffer> <silent> '.g:autopairs_shortcut_back_insert.' <C-R>=<SID>AutoPairsBackInsert()<CR>'
    end

    if g:autopairs_shortcut_toggle != ''
        " use <expr> to ensure showing the status when toggle
        execute 'inoremap <buffer> <silent> <expr> '.g:autopairs_shortcut_toggle.' <SID>AutoPairsToggle()'
        execute 'noremap <buffer> <silent> '.g:autopairs_shortcut_toggle.' :call <SID>AutoPairsToggle()<CR>'
    end

    if g:autopairs_shortcut_jump != ''
        execute 'inoremap <buffer> <silent> ' . g:autopairs_shortcut_jump. ' <ESC>:call <SID>AutoPairsJump()<CR>a'
        execute 'noremap <buffer> <silent> ' . g:autopairs_shortcut_jump. ' :call <SID>AutoPairsJump()<CR>'
    end

    if &keymap != ''
        let l:imsearch = &imsearch
        let l:iminsert = &iminsert
        let l:imdisable = &imdisable
        execute 'setlocal keymap=' . &keymap
        execute 'setlocal imsearch=' . l:imsearch
        execute 'setlocal iminsert=' . l:iminsert
        if l:imdisable
            execute 'setlocal imdisable'
        else
            execute 'setlocal noimdisable'
        end
    end

endf

func! s:ExpandMap(map)
    let map = a:map
    let map = substitute(map, '\(<Plug>\w\+\)', '\=maparg(submatch(1), "i")', 'g')
    let map = substitute(map, '\(<Plug>([^)]*)\)', '\=maparg(submatch(1), "i")', 'g')
    return map
endf

func! s:AutoPairsTryInit()
    if exists('b:loaded_autopairs')
        return
    end

    " for auto-pairs starts with 'a', so the priority is higher than supertab and vim-endwise
    "
    " vim-endwise doesn't support <Plug>AutoPairsReturn
    " when use <Plug>AutoPairsReturn will cause <Plug> isn't expanded
    "
    " supertab doesn't support <SID>AutoPairsReturn
    " when use <SID>AutoPairsReturn  will cause Duplicated <CR>
    "
    " and when load after vim-endwise will cause unexpected endwise inserted.
    " so always load autopairs at last

    " Buffer level keys mapping
    " comptible with other plugin
    if g:autopairs_map_CR && get(b:, "autopairs_map_CR", 1)
        if v:version == 703 && has('patch32') || v:version > 703
            " VIM 7.3 supports advancer maparg which could get <expr> info
            " then auto-pairs could remap <CR> in any case.
            let info = maparg('<CR>', 'i', 0, 1)
            if empty(info)
                let old_cr = '<CR>'
                let is_expr = 0
            else
                let old_cr = info['rhs']
                let old_cr = s:ExpandMap(old_cr)
                let old_cr = substitute(old_cr, '<SID>', '<SNR>' . info['sid'] . '_', 'g')
                let is_expr = info['expr']
                let wrapper_name = '<SID>AutoPairsOldCRWrapper73'
            endif
        else
            " VIM version less than 7.3
            " the mapping's <expr> info is lost, so guess it is expr or not, it's
            " not accurate.
            let old_cr = maparg('<CR>', 'i')
            if old_cr == ''
                let old_cr = '<CR>'
                let is_expr = 0
            else
                let old_cr = s:ExpandMap(old_cr)
                " old_cr contain (, I guess the old cr is in expr mode
                let is_expr = old_cr =~ '\V(' && toupper(old_cr) !~ '\V<C-R>'

                " The old_cr start with " it must be in expr mode
                let is_expr = is_expr || old_cr =~ '\v^"'
                let wrapper_name = '<SID>AutoPairsOldCRWrapper'
            end
        end

        if old_cr !~ 'AutoPairsReturn'
            if is_expr
                " remap <expr> to `name` to avoid mix expr and non-expr mode
                execute 'inoremap <buffer> <expr> <script> '. wrapper_name . ' ' . old_cr
                let old_cr = wrapper_name
            end
            " Always silent mapping
            execute 'inoremap <script> <buffer> <silent> <CR> '.old_cr.'<SID>AutoPairsReturn'
        end
    endif
    call s:AutoPairsInit()
endf

" Always silent the command
inoremap <silent> <SID>AutoPairsReturn <C-R>=<SID>AutoPairsReturn()<CR>
imap <script> <Plug>AutoPairsReturn <SID>AutoPairsReturn


au BufEnter * :call <SID>AutoPairsTryInit()
