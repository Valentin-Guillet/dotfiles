
let g:submode_timeout = 0

let s:original_split = ''

function! submode#set_split()
  let s:original_split = winnr()
endfunction

function! submode#reset_split()
  execute "normal " . s:original_split . ""
endfunction


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
call submode#map('resize', 'n', '', '=', reset_split . '<C-w>=')
