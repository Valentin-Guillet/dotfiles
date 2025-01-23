" Patch `vim-stay` plugin for two modifications:
" 1. Modify the `stay#ispersistent()` function that checks if the plugin
"    should be called on a given buffer.
"    By default, the plugin checks that the buftype is set to hidden,
"    but I don't use it so the condition is simply removed from the list
"    of checks
" 2. Remove the check for `g:SessionLoad` because it prevents my local plugin
"    `local_session` to run
" In practice, we redefine the `ispersistent()` function without the line that
" checks `bufhidden`, and we redefine the two main plugin functions MakeView
" and LoadView to use this modified function. We also remove the
" `exists('g:SessionLoad')` condition in LoadView

let s:script_info = getscriptinfo({"name": "vim-stay/plugin/stay.vim"})
if empty(s:script_info) | finish | endif
let s:script_id = string(s:script_info[0]["sid"])

function s:ispersistent(bufnr, volatile_ftypes) abort
  let l:bufpath = expand('#'.a:bufnr.':p') " empty on invalid buffer numbers
  return
  \ !empty(l:bufpath) &&
  \ getbufvar(a:bufnr, 'stay_ignore') isnot 1 &&
  \ getbufvar(a:bufnr, '&buflisted') is 1 &&
  \ index(['', 'acwrite'], getbufvar(a:bufnr, '&buftype')) isnot -1 &&
  \ filereadable(l:bufpath) &&
  \ stay#isftype(a:bufnr, a:volatile_ftypes) isnot 1 &&
  \ stay#istemp(l:bufpath) isnot 1
endfunction

let s:replace_function_list =<< eval END
function! <SNR>{s:script_id}_MakeView(stage, bufnr, winid) abort
  let l:state = stay#getbufstate(a:bufnr)
  let l:left  = get(l:state, 'left', {{}})
  if a:stage > 1 && !empty(l:left) && localtime() - get(l:left, a:stage-1, 0) <= 1
    return 0
  endif

  if pumvisible() || !stay#isviewwin(a:winid) || !s:ispersistent(a:bufnr, g:volatile_ftypes)
    return 0
  endif

  let l:done = stay#view#make(a:winid)
  call <SNR>{s:script_id}_HandleErrMsg(l:done)
  if l:done is  1
    let l:state.left = extend(l:left, {{string(a:stage): localtime()}})
  endif
  return l:done
endfunction

function! <SNR>{s:script_id}_LoadView(bufnr, winid) abort
  if pumvisible() || !stay#isviewwin(a:winid) || !s:ispersistent(a:bufnr, g:volatile_ftypes)
    return 0
  endif

  let l:done = stay#view#load(a:winid)
  call <SNR>{s:script_id}_HandleErrMsg(l:done)
  return l:done
endfunction
END

execute join(s:replace_function_list, "\n")
