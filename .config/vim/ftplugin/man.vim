
" Prevent sleuth as it can't detect weird indentation
let g:sleuth_man_heuristics = 0

setlocal laststatus=0

let g:ft_man_folding_enable = 1
setlocal foldlevelstart=99
setlocal foldlevel=1

" tabs in man pages are 8 spaces
setlocal tabstop=8

nnoremap <silent> <buffer> q :q<CR>
nnoremap <silent> <buffer> s /^\s*\zs-

noremap <silent> <buffer> <nowait> g gg
noremap <silent> <buffer> <nowait> d <C-d>
noremap <silent> <buffer> <nowait> D <C-f>
noremap <silent> <buffer> <nowait> u <C-u>
noremap <silent> <buffer> <nowait> U <C-b>

noremap <silent> <buffer> <nowait> [ <Cmd>call man#goto_section('b', 'n', v:count1)<CR>
noremap <silent> <buffer> <nowait> ] <Cmd>call man#goto_section('', 'n', v:count1)<CR>

noremap <silent> <buffer> <nowait> < <Cmd>call search('\<\(\f\<bar>:\)\+(\([nlpo]\<bar>\d[a-z]*\)\?)\(\W\<bar>$\)', 'b')<CR>
noremap <silent> <buffer> <nowait> > <Cmd>call search('\<\(\f\<bar>:\)\+(\([nlpo]\<bar>\d[a-z]*\)\?)\(\W\<bar>$\)')<CR>

map <silent> <buffer> x <Plug>NetrwBrowseX
noremap <silent> <buffer> o gf

augroup manResize
  autocmd!

  autocmd VimResized * call man#resize_win()
augroup END
