" Modification of christoomey's "vim-tmux-navigator" plugin to also resize
" panes. These modifications are taken from martin-louazel-engineering's fork
" (https://github.com/martin-louazel-engineering/vim-tmux-navigator)

" Get script ID
let s:script_info = getscriptinfo({"name": "vim-tmux-navigator/plugin/tmux_navigator.vim"})

if empty(s:script_info)
  finish
endif

let s:script_id = string(s:script_info[0]["sid"])

" Redefine functions from the original plugin that need to be called from our
" modifications
function! s:GetPluginFn(fn_name)
  execute "let s:" . a:fn_name . " = function(\"<SNR>" . s:script_id . "_" . a:fn_name . "\")"
endfunction

call s:GetPluginFn("TmuxCommand")
call s:GetPluginFn("TmuxVimPaneIsZoomed")
call s:GetPluginFn("NeedsVitalityRedraw")


if !exists("g:tmux_navigator_resize_step")
  let g:tmux_navigator_resize_step = 1
endif

function! s:VimResize(direction)
  let sep_direction = tr(a:direction, 'hjkl', 'ljjl')
  let plus_minus = tr(a:direction, 'hjkl', '-+-+')
  if !s:VimHasNeighbour(sep_direction)
    let plus_minus = plus_minus == '+' ? '-' : '+'
  end
  let vertical = tr(a:direction, 'hjkl', '1001')
  let vimCmd = (vertical ? 'vertical ' : '') . 'resize' . plus_minus . g:tmux_navigator_resize_step
  exec vimCmd
endfunction

" equivalent to 'winnr() == winnr(direction)' for vim < 8.1
function! s:VimHasNeighbour(direction)
  let current_position = win_screenpos(winnr())
  if a:direction == 'k'
    " Account for potential bufferline
    return current_position[0] > 2
  elseif a:direction == 'h'
    return current_position[1] != 1
  endif
  let win_nr = winnr('$')
  while win_nr > 0
    let position = win_screenpos(win_nr)
    let win_nr = win_nr - 1
    if a:direction == 'l' && (current_position[1] + winwidth(0)) < position[1]
      return 1
    elseif a:direction == 'j' && (current_position[0] + winheight(0)) < position[0]
      return 1
    endif
  endwhile
endfunction

function! s:TmuxHasNeighbour(direction)
  let tmux_direction = get({'h':'left', 'j':'bottom', 'k':'up', 'l':'right'}, a:direction)
  return !s:TmuxCommand("display-message -p '#{pane_at_" . tmux_direction . "}'")
endfunction

function! s:ShouldForwardResizeBackToTmux(direction)
  if g:tmux_navigator_disable_when_zoomed && s:TmuxVimPaneIsZoomed()
    return 0
  endif
  if tabpagewinnr(tabpagenr(), '$') == 1
    return 1
  endif
  let xy_axis=tr(a:direction, 'hjkl', 'ljjl')
  " case: there are no more vim neighboring windows, and there is still at
  " least one tmux pane in the direction of the separator that can be shrunk
  if !s:VimHasNeighbour(xy_axis) && s:TmuxHasNeighbour(xy_axis)
    return 1
  elseif !s:VimHasNeighbour(xy_axis) && !s:TmuxHasNeighbour(xy_axis)
    let xy_axis_reverse=tr(xy_axis, 'jl', 'kh')
    " case: If there is one vim split before along the axis, move it
    " Otherwise, forward to tmux
    return !s:VimHasNeighbour(xy_axis_reverse)
  endif
  return 0
endfunction

" Returns an array with all windows' win_screenpos
function! s:VimLayout()
  let layout = []
  let win_nr = winnr('$')
  while win_nr > 0
    call add(layout, win_screenpos(win_nr))
    let win_nr = win_nr - 1
  endwhile
  return layout
endfunction

function! s:TmuxAwareResize(direction)
  if s:ShouldForwardResizeBackToTmux(a:direction)
    let args = 'resize-pane -t ' . shellescape($TMUX_PANE) . ' -' . tr(a:direction, 'hjkl', 'LDUR') . " " . g:tmux_navigator_resize_step
    silent call s:TmuxCommand(args)
  else
    let l:layout_before = s:VimLayout()
    call s:VimResize(a:direction)
    let l:layout_after = s:VimLayout()
    " Should we 'push' a neighbouring tmux panes to grow the current vim split ?
    if l:layout_before == l:layout_after
      let tmux_sep_direction=tr(a:direction, 'hjkl', 'ljjl')
      if !s:TmuxHasNeighbour(tmux_sep_direction)
        let tmux_sep_direction = tr(tmux_sep_direction, 'jl', 'kh')
      endif
      " If we are moving away from the separator, we should resize the
      " previous pane along the axes
      let tmux_direction_previous = get({'h':'left', 'j':'up', 'k':'up', 'l':'left'}, tmux_sep_direction)
      let tmux_pane_to_resize = (tmux_sep_direction == a:direction) ? shellescape($TMUX_PANE) : "{" . tmux_direction_previous . "-of}"
      let tmux_resize_direction = (tmux_sep_direction == a:direction) ? tr(a:direction, 'hjkl', 'LDUR') : tr(a:direction, 'hjkl', 'LUUL')
      let args = 'resize-pane -t ' . tmux_pane_to_resize . ' -' . tmux_resize_direction . " " . g:tmux_navigator_resize_step
      silent call s:TmuxCommand(args)
    endif
  endif
  if s:NeedsVitalityRedraw()
    redraw!
  endif
endfunction


if empty($TMUX)
  command! TmuxResizeLeft call s:VimResize('h')
  command! TmuxResizeDown call s:VimResize('j')
  command! TmuxResizeUp call s:VimResize('k')
  command! TmuxResizeRight call s:VimResize('l')
  finish
endif

command! TmuxResizeLeft call s:TmuxAwareResize('h')
command! TmuxResizeDown call s:TmuxAwareResize('j')
command! TmuxResizeUp call s:TmuxAwareResize('k')
command! TmuxResizeRight call s:TmuxAwareResize('l')
