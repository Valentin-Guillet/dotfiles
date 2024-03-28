
" Get script ID
let s:script_info = getscriptinfo({"name": "vim-surround/plugin/surround.vim"})

if empty(s:script_info)
  finish
endif

let s:script_id = string(s:script_info[0]["sid"])
let s:function_name = "<SNR>" . s:script_id . "_inputtarget"

function s:patched_inputtarget()
  let l:Getchar_fun = function("<SNR>" . s:script_id . "_getchar")
  let c = l:Getchar_fun()
  while c =~ '^\d\+$'
    let c .= l:Getchar_fun()
  endwhile
  if c == " "
    let c .= l:Getchar_fun()
  endif
  if c =~ "\<Esc>\|\<C-C>\|\0"
    return ""
  else
    if c == "s"
      let c = matchstr(getline('.'), '\%' . col('.') . 'c.')
    endif
    return c
  endif
endfunction

execute "function! " . s:function_name . "() \n return s:patched_inputtarget() \n endfunction"
