
" Variables

if !exists('g:submode_always_show_submode')
  let g:submode_always_show_submode = 0
endif

if !exists('g:submode_keep_leaving_key')
  let g:submode_keep_leaving_key = 0
endif

if !exists('g:submode_keyseqs_to_leave')
  let g:submode_keyseqs_to_leave = ['<Esc>']
endif

if !exists('g:submode_timeout')
  let g:submode_timeout = &timeout
endif

if !exists('g:submode_timeoutlen')
  let g:submode_timeoutlen = &timeoutlen
endif

"" See s:set_up_options() and s:restore_options().
"
" let s:original_showcmd = &showcmd
" let s:original_showmode = &showmode
" let s:original_timeout = &timeout
" let s:original_timeoutlen = &timeoutlen
" let s:original_ttimeout = &ttimeout
" let s:original_ttimeoutlen = &ttimeoutlen

if !exists('s:options_overridden_p')
  let s:options_overridden_p = 0
endif

" A padding string to wipe out internal key mappings in 'showcmd' area.  (gh-3)
"
" We use no-break spaces (U+00A0) or dots, depending of the current 'encoding'.
" Because
"
" * A normal space (U+0020) is rendered as "<20>" since Vim 7.4.116.
" * U+00A0 is rendered as an invisible glyph if 'encoding' is set to one of
"   Unicode encodings.  Otherwise "| " is rendered instead.
let s:STEALTH_TYPEAHEAD =
\ &g:encoding =~# '^u'
\ ? repeat("\<Char-0xa0>", 5)
\ : repeat('.', 10)

let s:current_submode = ''
let s:original_split = ''


" Interface
" :SubmodeRestoreOptions

command! -bar -nargs=0 SubmodeRestoreOptions  call submode#restore_options()

function! submode#set_split()
  let s:original_split = winnr()
endfunction

function! submode#reset_split()
  execute "normal " . s:original_split . ""
endfunction

function! submode#set_resize_mode()
  let set_split = ':call submode#set_split()<CR>'
  let reset_split = ':call submode#reset_split()<CR>' . set_split
  call submode#enter_with('resize', 'n', '', '<leader>j', set_split . '<C-w>k5<C-w>+')
  call submode#enter_with('resize', 'n', '', '<leader>k', set_split . '<C-w>k5<C-w>-')
  call submode#enter_with('resize', 'n', '', '<leader>h', set_split . '<C-w>h5<C-w><')
  call submode#enter_with('resize', 'n', '', '<leader>l', set_split . '<C-w>h5<C-w>>')
  call submode#map('resize', 'n', '', 'j', reset_split . '<C-w>k5<C-w>+')
  call submode#map('resize', 'n', '', 'k', reset_split . '<C-w>k5<C-w>-')
  call submode#map('resize', 'n', '', 'h', reset_split . '<C-w>h5<C-w><')
  call submode#map('resize', 'n', '', 'l', reset_split . '<C-w>h5<C-w>>')
  call submode#map('resize', 'n', '', 'J', reset_split . '<C-w>k<C-w>+')
  call submode#map('resize', 'n', '', 'K', reset_split . '<C-w>k<C-w>-')
  call submode#map('resize', 'n', '', 'H', reset_split . '<C-w>h<C-w><')
  call submode#map('resize', 'n', '', 'L', reset_split . '<C-w>h<C-w>>')
endfunction

function! submode#current()
  return s:current_submode
endfunction

function! submode#enter_with(submode, modes, options, lhs, ...)
  let rhs = 0 < a:0 ? a:1 : '<Nop>'
  for mode in s:each_char(a:modes)
    call s:define_entering_mapping(a:submode, mode, a:options, a:lhs, rhs)
  endfor
  return
endfunction

function! submode#leave_with(submode, modes, options, lhs)
  let options = substitute(a:modes, 'e', '', 'g')  " <Nop> is not expression.
  return submode#map(a:submode, a:modes, options . 'x', a:lhs, '<Nop>')
endfunction

function! submode#map(submode, modes, options, lhs, rhs)
  for mode in s:each_char(a:modes)
    call s:define_submode_mapping(a:submode, mode, a:options, a:lhs, a:rhs)
  endfor
  return
endfunction

function! submode#restore_options()
  call s:restore_options()
  return
endfunction

function! submode#unmap(submode, modes, options, lhs)
  for mode in s:each_char(a:modes)
    call s:undefine_submode_mapping(a:submode, mode, a:options, a:lhs)
  endfor
  return
endfunction


" Core
function! s:define_entering_mapping(submode, mode, options, lhs, rhs)
  execute s:map_command(a:mode, 'r')
  \       s:map_options(s:filter_flags(a:options, 'bu'))
  \       (a:lhs)
  \       (s:named_key_before_entering_with(a:submode, a:lhs)
  \        . s:named_key_before_entering(a:submode)
  \        . s:named_key_enter(a:submode))

  if !s:mapping_exists_p(s:named_key_enter(a:submode), a:mode)
    " When the given submode is not defined yet - define the default key
    " mappings to leave the submode.
    for keyseq in g:submode_keyseqs_to_leave
      call submode#leave_with(a:submode, a:mode, a:options, keyseq)
    endfor
  endif

  execute s:map_command(a:mode, s:filter_flags(a:options, 'r'))
  \       s:map_options(s:filter_flags(a:options, 'besu'))
  \       s:named_key_before_entering_with(a:submode, a:lhs)
  \       a:rhs
  execute s:map_command(a:mode, '')
  \       s:map_options('e')
  \       s:named_key_before_entering(a:submode)
  \       printf('<SID>on_entering_submode(%s)', string(a:submode))
  execute s:map_command(a:mode, 'r')
  \       s:map_options('')
  \       s:named_key_enter(a:submode)
  \       (s:named_key_before_action(a:submode)
  \        . s:named_key_prefix(a:submode))

  execute s:map_command(a:mode, '')
  \       s:map_options('e')
  \       s:named_key_before_action(a:submode)
  \       printf('<SID>on_executing_action(%s)', string(a:submode))
  execute s:map_command(a:mode, 'r')
  \       s:map_options('')
  \       s:named_key_prefix(a:submode)
  \       s:named_key_leave(a:submode)
  " NB: :map-<expr> cannot be used for s:on_leaving_submode(),
  "     because it uses some commands not allowed in :map-<expr>.
  execute s:map_command(a:mode, '')
  \       s:map_options('s')
  \       s:named_key_leave(a:submode)
  \       printf('%s<SID>on_leaving_submode(%s)<Return>',
  \              a:mode =~# '[ic]' ? '<C-r>=' : '@=',
  \              string(a:submode))

  return
endfunction

function! s:define_submode_mapping(submode, mode, options, lhs, rhs)
  execute s:map_command(a:mode, 'r')
  \       s:map_options(s:filter_flags(a:options, 'bu'))
  \       (s:named_key_prefix(a:submode) . a:lhs)
  \       (s:named_key_rhs(a:submode, a:lhs)
  \        . (s:has_flag_p(a:options, 'x')
  \           ? s:named_key_leave(a:submode)
  \           : s:named_key_enter(a:submode)))
  execute s:map_command(a:mode, s:filter_flags(a:options, 'r'))
  \       s:map_options(s:filter_flags(a:options, 'besu'))
  \       s:named_key_rhs(a:submode, a:lhs)
  \       a:rhs

  let keys = s:split_keys(a:lhs)
  for n in range(1, len(keys) - 1)
    let first_n_keys = join(keys[:-(n+1)], '')
    silent! execute s:map_command(a:mode, 'r')
    \               s:map_options(s:filter_flags(a:options, 'bu'))
    \               (s:named_key_prefix(a:submode) . first_n_keys)
    \               s:named_key_leave(a:submode)
  endfor

  return
endfunction

function! s:undefine_submode_mapping(submode, mode, options, lhs)
  execute s:map_command(a:mode, 'u')
  \       s:map_options(s:filter_flags(a:options, 'b'))
  \       s:named_key_rhs(a:submode, a:lhs)

  let keys = s:split_keys(a:lhs)
  for n in range(len(keys), 1, -1)
    let first_n_keys = join(keys[:n-1], '')
    execute s:map_command(a:mode, 'u')
    \       s:map_options(s:filter_flags(a:options, 'b'))
    \       s:named_key_prefix(a:submode) . first_n_keys
    if s:longer_mapping_exists_p(s:named_key_prefix(a:submode), first_n_keys)
      execute s:map_command(a:mode, 'r')
      \       s:map_options(s:filter_flags(a:options, 'b'))
      \       s:named_key_prefix(a:submode) . first_n_keys
      \       s:named_key_leave(a:submode)
      break
    endif
  endfor

  return
endfunction


" Misc.
function! s:each_char(s)
  return split(a:s, '.\zs')
endfunction

function! s:filter_flags(s, cs)
  return join(map(s:each_char(a:cs), 's:has_flag_p(a:s, v:val) ? v:val : ""'),
  \           '')
endfunction

function! s:has_flag_p(s, c)
  return 0 <= stridx(a:s, a:c)
endfunction

function! s:insert_mode_p(mode)
  return a:mode =~# '^[iR]'
endfunction

function! s:longer_mapping_exists_p(submode, lhs)
  " FIXME: Implement the proper calculation.
  "        Note that mapcheck() can't be used for this purpose because it may
  "        act as s:shorter_mapping_exists_p() if there is such a mapping.
  return !0
endfunction

function! s:map_command(mode, flags)
  if s:has_flag_p(a:flags, 'u')
    return a:mode . 'unmap'
  else
    return a:mode . (s:has_flag_p(a:flags, 'r') ? 'map' : 'noremap')
  endif
endfunction

function! s:map_options(options)
  let _ = {
  \   'b': '<buffer>',
  \   'e': '<expr>',
  \   's': '<silent>',
  \   'u': '<unique>',
  \ }
  return join(map(s:each_char(a:options), 'get(_, v:val, "")'))
endfunction

function! s:mapping_exists_p(keyseq, mode)
  return maparg(a:keyseq, a:mode) != ''
endfunction

function! s:may_override_showmode_p(mode)
  " Normal mode / Visual mode (& its variants) / Insert mode (& its variants)
  return a:mode =~# "^[nvV\<C-v>sS\<C-s>]" || s:insert_mode_p(a:mode)
endfunction

function! s:named_key_before_action(submode)
  return printf('<Plug>(submode-before-action:%s)', a:submode)
endfunction

function! s:named_key_before_entering(submode)
  return printf('<Plug>(submode-before-entering:%s)', a:submode)
endfunction

function! s:named_key_before_entering_with(submode, lhs)
  return printf('<Plug>(submode-before-entering:%s:with:%s)', a:submode, a:lhs)
endfunction

function! s:named_key_enter(submode)
  return printf('<Plug>(submode-enter:%s)', a:submode)
endfunction

function! s:named_key_leave(submode)
  return printf('<Plug>(submode-leave:%s)', a:submode)
endfunction

function! s:named_key_prefix(submode)
  return printf('<Plug>(submode-prefix:%s)%s', a:submode, s:STEALTH_TYPEAHEAD)
endfunction

function! s:named_key_rhs(submode, lhs)
  return printf('<Plug>(submode-rhs:%s:for:%s)', a:submode, a:lhs)
endfunction

function! s:on_entering_submode(submode)
  call s:set_up_options(a:submode)
  return ''
endfunction

function! s:on_executing_action(submode)
  if (s:original_showmode || g:submode_always_show_submode)
  \  && s:may_override_showmode_p(mode())
    echohl ModeMsg
    echo '-- Submode:' a:submode '--'
    echohl None
  endif
  return ''
endfunction

function! s:on_leaving_submode(submode)
  if (s:original_showmode || g:submode_always_show_submode)
  \  && s:may_override_showmode_p(mode())
    if s:insert_mode_p(mode())
      let cursor_position = getpos('.')
    endif

      " BUGS: :redraw! doesn't redraw 'showmode'.
    execute "normal! \<C-l>"

    if s:insert_mode_p(mode())
      call setpos('.', cursor_position)
    endif
  endif
  if !g:submode_keep_leaving_key && getchar(1) isnot 0
    " To completely ignore unbound key sequences in a submode,
    " here we have to fetch and drop the last key in the key sequence.
    call getchar()
  endif
  call s:restore_options()
  return ''
endfunction

function! s:remove_flag(s, c)
  " Assumption: a:c is not a meta character.
  return substitute(a:s, a:c, '', 'g')
endfunction

function! s:restore_options()
  if submode#current() == "resize"
    call submode#reset_split()
  endif
  if !s:options_overridden_p
    return
  endif
  let s:options_overridden_p = 0

  let &showcmd = s:original_showcmd
  let &showmode = s:original_showmode
  let &timeout = s:original_timeout
  let &timeoutlen = s:original_timeoutlen
  let &ttimeout = s:original_ttimeout
  let &ttimeoutlen = s:original_ttimeoutlen

  let s:current_submode = ''

  return
endfunction

function! s:set_up_options(submode)
  if s:options_overridden_p
    return
  endif
  let s:options_overridden_p = !0

  let s:original_showcmd = &showcmd
  let s:original_showmode = &showmode
  let s:original_timeout = &timeout
  let s:original_timeoutlen = &timeoutlen
  let s:original_ttimeout = &ttimeout
  let s:original_ttimeoutlen = &ttimeoutlen

  " NB: 'showcmd' must be enabled to render the cursor properly.
  " If 'showcmd' is disabled and the current submode message is rendered, the
  " cursor is rendered at the end of the message, not the actual position in
  " the current window.  (gh-9)
  set showcmd
  set noshowmode
  let &timeout = g:submode_timeout
  let &ttimeout = s:original_timeout ? !0 : s:original_ttimeout
  let &timeoutlen = g:submode_timeoutlen
  let &ttimeoutlen = s:original_ttimeoutlen < 0
  \                  ? s:original_timeoutlen
  \                  : s:original_ttimeoutlen

  let s:current_submode = a:submode

  return
endfunction

function! s:split_keys(keyseq)
  " Assumption: Special keys such as <C-u> are escaped with < and >, i.e.,
  "             a:keyseq doesn't directly contain any escape sequences.
  return split(a:keyseq, '\(<[^<>]\+>\|.\)\zs')
endfunction

