
let g:submode_timeout = 0

let s:original_split = ''

function! submode#set_split()
  let s:original_split = winnr()
endfunction

function! submode#reset_split()
  execute "normal! " . s:original_split . "\<C-W>\<C-W>"
endfunction


let set_split = ':call submode#set_split()<CR>'
let reset_split = ':call submode#reset_split()<CR>' . set_split
call submode#enter_with('resize', 'n', '', '<leader>j', set_split . '<C-w>k5<C-w>+')
call submode#enter_with('resize', 'n', '', '<leader>k', set_split . '<C-w>k5<C-w>-')
call submode#enter_with('resize', 'n', '', '<leader>h', set_split . '<C-w>h5<C-w><')
call submode#enter_with('resize', 'n', '', '<leader>l', set_split . '<C-w>h5<C-w>>')

" Resize by steps of 5
call submode#map('resize', 'n', '', 'j', reset_split . '<C-w>k5<C-w>+')
call submode#map('resize', 'n', '', 'k', reset_split . '<C-w>k5<C-w>-')
call submode#map('resize', 'n', '', 'h', reset_split . '<C-w>h5<C-w><')
call submode#map('resize', 'n', '', 'l', reset_split . '<C-w>h5<C-w>>')

" Resize by steps of 1
call submode#map('resize', 'n', '', 'J', reset_split . '<C-w>k<C-w>+')
call submode#map('resize', 'n', '', 'K', reset_split . '<C-w>k<C-w>-')
call submode#map('resize', 'n', '', 'H', reset_split . '<C-w>h<C-w><')
call submode#map('resize', 'n', '', 'L', reset_split . '<C-w>h<C-w>>')

" Change window
call submode#map('resize', 'n', '', '<C-j>', '<C-w>j' . set_split)
call submode#map('resize', 'n', '', '<C-k>', '<C-w>k' . set_split)
call submode#map('resize', 'n', '', '<C-h>', '<C-w>h' . set_split)
call submode#map('resize', 'n', '', '<C-l>', '<C-w>l' . set_split)

" Equalize windows
call submode#map('resize', 'n', '', '=', reset_split . '<C-w>=')

