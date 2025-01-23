" Patch `surround` plugin to add the `s` shortcut that corresponds to any symbol
" under the cursor
" E.g. `css` = change surrounding under the cursor,
" so on a `(`, it is exactly equivalent to typing `cs(`

let s:script_info = getscriptinfo({"name": "vim-surround/plugin/surround.vim"})
if empty(s:script_info) | finish | endif
let s:script_id = string(s:script_info[0]["sid"])

let s:replace_cmd_list =<< eval END
function! <SNR>{s:script_id}_inputtarget()
  let c = <SNR>{s:script_id}_getchar()
  while c =~ '^\d\+$'
    let c .= <SNR>{s:script_id}_getchar()
  endwhile
  if c == " "
    let c .= <SNR>{s:script_id}_getchar()
  endif
  if c =~ "\<Esc>\|\<C-C>\|\0"
    return ""
  elseif c == "s"
    return matchstr(getline('.'), '\%' . col('.') . 'c.')
  else
    return c
  endif
endfunction
END

execute join(s:replace_cmd_list, "\n")
