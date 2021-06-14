
let g:submode_timeout = 0

let s:original_split = ''

function! submode#set_split()
    let s:original_split = winnr()
endfunction

function! submode#reset_split()
    execute "normal! " . s:original_split . "\<C-W>\<C-W>"
endfunction


let s:set_split = ':call submode#set_split()<CR>'
let s:reset_split = ':call submode#reset_split()<CR>' . s:set_split
call submode#enter_with('resize', 'n', '', '<leader>j', s:set_split . '<C-w>k5<C-w>+')
call submode#enter_with('resize', 'n', '', '<leader>k', s:set_split . '<C-w>k5<C-w>-')
call submode#enter_with('resize', 'n', '', '<leader>h', s:set_split . '<C-w>h5<C-w><')
call submode#enter_with('resize', 'n', '', '<leader>l', s:set_split . '<C-w>h5<C-w>>')

" Resize by steps of 5
call submode#map('resize', 'n', '', 'j', s:reset_split . '<C-w>k5<C-w>+')
call submode#map('resize', 'n', '', 'k', s:reset_split . '<C-w>k5<C-w>-')
call submode#map('resize', 'n', '', 'h', s:reset_split . '<C-w>h5<C-w><')
call submode#map('resize', 'n', '', 'l', s:reset_split . '<C-w>h5<C-w>>')

" Resize by steps of 1
call submode#map('resize', 'n', '', 'J', s:reset_split . '<C-w>k<C-w>+')
call submode#map('resize', 'n', '', 'K', s:reset_split . '<C-w>k<C-w>-')
call submode#map('resize', 'n', '', 'H', s:reset_split . '<C-w>h<C-w><')
call submode#map('resize', 'n', '', 'L', s:reset_split . '<C-w>h<C-w>>')

" Change window
call submode#map('resize', 'n', '', '<C-j>', '<C-w>j' . s:set_split)
call submode#map('resize', 'n', '', '<C-k>', '<C-w>k' . s:set_split)
call submode#map('resize', 'n', '', '<C-h>', '<C-w>h' . s:set_split)
call submode#map('resize', 'n', '', '<C-l>', '<C-w>l' . s:set_split)

" Equalize windows
call submode#map('resize', 'n', '', '=', s:reset_split . '<C-w>=')

