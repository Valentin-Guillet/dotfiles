" Plugin to switch from vim to neovim using tmux:
" we catch USR1 signal to create a session and quit vim
" and tmux opens nvim with this session

if exists("g:loaded_nvim_switch")
    finish
endif
let g:loaded_nvim_switch = 1

let s:switch_file = "/tmp/vim_switch.vim"

function! s:CreateSessionAndQuit()
    if !empty(getbufinfo({"bufmodified": 1}))
        writefile([], s:switch_file)
        echohl ErrorMsg
        echom "[Switch] Can't quit vim: buffer not saved!"
        echohl None
        return
    endif
    execute "mksession! " . s:switch_file
    quitall
endfunction


augroup nvimSwitch
    autocmd!
    autocmd SigUSR1 * call s:CreateSessionAndQuit()
augroup END

