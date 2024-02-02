" Define a submode in which to resize different panes in the same fashion as
" tmux pane management

if exists('g:loaded_resize_submode')
    finish
endif
let g:loaded_resize_submode = 1

let g:submode_timeout = 0

" Needed to use keys that start with an <Esc> sequence, such as <M-.> and arrow keys
" https://vi.stackexchange.com/questions/4518/how-to-use-arrow-keys-mappings-in-vim-submode-plugin-on-linux-terminal
let g:submode_keyseqs_to_leave = []

let s:original_split = ''

function! resize_submode#set_split()
    let s:original_split = winnr()
endfunction

function! resize_submode#reset_split()
    execute "normal! " . s:original_split . "\<C-W>\<C-W>"
endfunction


let s:set_split = '<cmd>call resize_submode#set_split()<CR>'
let s:reset_split = '<cmd>call resize_submode#reset_split()<CR>' . s:set_split
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
call submode#map('resize', 'n', '', '<M-j>', '<C-w>j' . s:set_split)
call submode#map('resize', 'n', '', '<M-k>', '<C-w>k' . s:set_split)
call submode#map('resize', 'n', '', '<M-h>', '<C-w>h' . s:set_split)
call submode#map('resize', 'n', '', '<M-l>', '<C-w>l' . s:set_split)

" Equalize windows
call submode#map('resize', 'n', '', '=', s:reset_split . '<C-w>=')

