
" Prevent sleuth as it can't detect weird indentation
let g:sleuth_man_heuristics = 0

setlocal laststatus=0

let g:ft_man_folding_enable = 1
setlocal foldlevelstart=99
setlocal foldlevel=1

" tabs in man pages are 8 spaces
setlocal tabstop=8

nnoremap <buffer> <silent> q :q<CR>
nnoremap <buffer> s /^\s*\zs-

noremap <buffer> <silent> <nowait> g gg
noremap <buffer> <silent> <nowait> d <C-d>
noremap <buffer> <silent> <nowait> D <C-f>
noremap <buffer> <silent> <nowait> u <C-u>
noremap <buffer> <silent> <nowait> U <C-b>

noremap <buffer> <silent> <nowait> [ <Cmd>call man#goto_section('b', 'n', v:count1)<CR>
noremap <buffer> <silent> <nowait> ] <Cmd>call man#goto_section('', 'n', v:count1)<CR>

noremap <buffer> <silent> <nowait> < <Cmd>call search('\<\(\f\<bar>:\)\+(\([nlpo]\<bar>\d[a-z]*\)\?)\(\W\<bar>$\)', 'b')<CR>
noremap <buffer> <silent> <nowait> > <Cmd>call search('\<\(\f\<bar>:\)\+(\([nlpo]\<bar>\d[a-z]*\)\?)\(\W\<bar>$\)')<CR>

map <buffer> <silent> x gx
noremap <buffer> <silent> o gf

nnoremap <buffer> <silent> <C-]> <Cmd>call man#goto_link(v:count)<CR>

augroup manResize
  autocmd!

  autocmd VimResized * call man#resize_win()
augroup END
