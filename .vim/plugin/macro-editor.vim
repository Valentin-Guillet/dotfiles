 
function! YankToRegister()
  exe printf('norm! ^"%sy$', b:registername)
endfunction

function! OpenMacroEditorWindow(registername)
  let name = 'MacroEditor'
  if bufexists(name)
    echohl WarningMsg
    echom "Can only edit one macro at a time"
    echohl None
    let win = bufwinnr(name)
    exe printf('%d . wincmd w', win)
    return
  endif
  let height = 3
  execute height 'new ' name
  let b:registername = a:registername
  setlocal bufhidden=wipe noswapfile nobuflisted
  silent! exe printf('norm! "%sp', b:registername)
  set nomodified
  augroup MacroEditor
    au!
    au BufWriteCmd <buffer> call YankToRegister()
    au BufWriteCmd <buffer> set nomodified
  augroup END
endfunction

command! -nargs=1 MacroEdit call OpenMacroEditorWindow("<args>")
nnoremap <expr> gm ":MacroEdit " . nr2char(getchar()) . "<CR>"

