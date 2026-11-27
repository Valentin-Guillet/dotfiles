" Scratch buffer management for Vim.
"
" Commands:
"   :ScratchRun        Create a new scratch buffer
"   :ScratchNew        Alias for :ScratchRun
"   :ScratchList       Browse existing scratch buffers
"   :ScratchDeleteAll  Delete all scratch buffers and files
"
" Buffer-local mappings:
"   <leader>y  Yank to system clipboard
"   <leader>p  Paste from system clipboard
"   <leader>q  Quit the scratch buffer
"
" Global mappings:
"   <Space><Space>  Open the scratch history picker

if exists('g:loaded_scratch_plugin')
    finish
endif
let g:loaded_scratch_plugin = 1


" ============================================================================
" Paths and filenames
" ============================================================================

function! s:ScratchDirectory() abort
    let l:base = empty($XDG_DATA_HOME)
                \ ? expand('~/.local/share')
                \ : expand($XDG_DATA_HOME)

    return l:base . '/vim/scratch'
endfunction


function! s:ScratchFilename() abort
    let l:dir = s:ScratchDirectory()

    if !isdirectory(l:dir)
        call mkdir(l:dir, 'p', 0700)
    endif

    let l:timestamp = strftime('%Y%m%d-%H%M%S')
    let l:path = l:dir . '/' . l:timestamp . '.txt'
    let l:counter = 1

    " Avoid reusing a filename, including for an unsaved buffer.
    while getftype(l:path) !=# '' || bufnr(l:path) != -1
        let l:path = l:dir . '/' . l:timestamp . '-' . l:counter . '.txt'
        let l:counter += 1
    endwhile

    return l:path
endfunction


" ============================================================================
" Scratch buffer configuration
" ============================================================================

function! s:ConfigureScratchBuffer() abort
    let b:scratch_buffer = 1
    let b:scratch_path = expand('%:p')

    setlocal filetype=text
    setlocal undofile
    setlocal spell

    nnoremap <buffer> <leader>y "+y
    xnoremap <buffer> <leader>y "+y

    nnoremap <buffer> <leader>p "+p
    xnoremap <buffer> <leader>p "+p

    nnoremap <buffer> <leader>q :quit<CR>
endfunction


" ============================================================================
" Scratch buffer creation
" ============================================================================

function! s:ScratchRun() abort
    let l:path = s:ScratchFilename()
    execute 'edit ' . fnameescape(l:path)
    call s:ConfigureScratchBuffer()
    startinsert
endfunction


" ============================================================================
" Scratch cleanup
" ============================================================================

function! s:IsWhitespace(lines) abort
    for l:line in a:lines
        if l:line =~# '\S'
            return 0
        endif
    endfor

    return 1
endfunction


function! s:ScratchCleanup(bufnr) abort
    if !getbufvar(a:bufnr, 'scratch_buffer', 0)
        return
    endif

    let l:path = getbufvar(a:bufnr, 'scratch_path', '')

    if empty(l:path) || !filereadable(l:path)
        return
    endif

    " Only inspect the on-disk contents.
    " Vim's 'confirm' option handles unsaved changes.
    if s:IsWhitespace(readfile(l:path))
        call delete(l:path)
    endif
endfunction


function! s:ScratchCleanupAll() abort
    for l:buf in getbufinfo()
        call s:ScratchCleanup(l:buf.bufnr)
    endfor
endfunction


" ============================================================================
" Delete all scratch files
" ============================================================================

function! s:ScratchDeleteAll() abort
    let l:dir = s:ScratchDirectory()
    let l:paths = glob(l:dir . '/*.txt', 0, 1)
    let l:buffers = []

    " Include scratch buffers that have not yet been saved to disk.
    for l:info in getbufinfo()
        if !getbufvar(l:info.bufnr, 'scratch_buffer', 0)
            continue
        endif

        let l:path = getbufvar(l:info.bufnr, 'scratch_path', '')

        if !empty(l:path) && index(l:paths, l:path) < 0
            call add(l:paths, l:path)
        endif

        call add(l:buffers, l:info.bufnr)
    endfor

    if empty(l:paths) && empty(l:buffers)
        echo 'No scratch files to delete.'
        return
    endif

    let l:choice = confirm(
                \ printf(
                \   'Delete all %d scratch item(s) and discard %d open buffer(s)?',
                \   len(l:paths),
                \   len(l:buffers)
                \ ),
                \ "&Delete\n&Cancel",
                \ 2
                \ )

    if l:choice != 1
        echo 'Deletion cancelled.'
        return
    endif

    " Delete files from disk.
    let l:deleted = 0
    let l:failed = []

    for l:path in l:paths
        if getftype(l:path) ==# ''
            continue
        endif

        if delete(l:path) == 0
            let l:deleted += 1
        else
            call add(l:failed, l:path)
        endif
    endfor

    " Wipe open buffers, except those whose files could not be deleted.
    let l:closed = 0

    for l:bufnr in l:buffers
        if !bufexists(l:bufnr)
            continue
        endif

        let l:path = getbufvar(l:bufnr, 'scratch_path', '')

        if index(l:failed, l:path) >= 0
            continue
        endif

        " The confirmation above explicitly authorizes discarding changes.
        execute 'silent! bwipeout! ' . l:bufnr

        if !bufexists(l:bufnr)
            let l:closed += 1
        endif
    endfor

    echo printf(
                \ 'Deleted %d scratch file(s); closed %d buffer(s).',
                \ l:deleted,
                \ l:closed
                \ )

    if !empty(l:failed)
        echohl WarningMsg
        echomsg 'Could not delete: ' . join(l:failed, ', ')
        echohl None
    endif
endfunction


" ============================================================================
" Scratch history picker
" ============================================================================

function! s:ScratchCompare(a, b) abort
    let l:time_a = getftime(s:ScratchDirectory() . '/' . a:a)
    let l:time_b = getftime(s:ScratchDirectory() . '/' . a:b)

    " Newest files first.
    if l:time_a != l:time_b
        return l:time_b - l:time_a
    endif

    " Break ties using descending filenames.
    if a:a ==# a:b
        return 0
    endif

    return a:a ># a:b ? -1 : 1
endfunction


function! s:ScratchDisplay(path) abort
    let l:timestamp = getftime(a:path)
    let l:date = strftime('%d %b %H:%M', l:timestamp)

    let l:lines = readfile(a:path)
    let l:title = '[empty]'

    for l:line in l:lines
        let l:line = trim(l:line)

        if !empty(l:line)
            let l:title = substitute(l:line, '\t', ' ', 'g')
            break
        endif
    endfor

    " Keep the picker readable.
    let l:title = strcharpart(l:title, 0, 70)

    return printf('%s │ %s', l:date, l:title)
endfunction


function! s:ScratchListSink(lines) abort
    if len(a:lines) < 2
        return
    endif

    let l:key = a:lines[0]
    let l:fields = split(a:lines[1], "\t", 1)

    if len(l:fields) < 2
        return
    endif

    let l:filename = l:fields[1]
    let l:path = s:ScratchDirectory() . '/' . l:filename

    if l:key ==# 'ctrl-d'
        if confirm(
                    \ 'Delete scratch file "' . l:filename . '"?',
                    \ "&Yes\n&No",
                    \ 2
                    \ ) == 1

            if delete(l:path) == 0
                echo 'Deleted: ' . l:filename
            else
                echoerr 'Could not delete: ' . l:filename
            endif
        endif

        return
    endif

    if !filereadable(l:path)
        echoerr 'Scratch file no longer exists: ' . l:filename
        return
    endif

    let l:command = {
                \ 'ctrl-t': 'tabedit',
                \ 'ctrl-x': 'split',
                \ 'ctrl-v': 'vsplit'
                \ }

    let l:open_command = get(l:command, l:key, 'edit')

    execute l:open_command . ' ' . fnameescape(l:path)

    call s:ConfigureScratchBuffer()

    startinsert
endfunction


function! s:ScratchList() abort
    let l:dir = s:ScratchDirectory()

    if !isdirectory(l:dir)
        echo 'No scratch files found.'
        return
    endif

    " Collect filenames and sort by modification time.
    let l:paths = glob(l:dir . '/*.txt', 0, 1)
    let l:files = []

    for l:path in l:paths
        call add(l:files, fnamemodify(l:path, ':t'))
    endfor

    call sort(l:files, function('<SID>ScratchCompare'))

    if empty(l:files)
        echo 'No scratch files found.'
        return
    endif

    " Build display entries: descriptive text + actual filename.
    let l:source = []

    for l:filename in l:files
        let l:path = l:dir . '/' . l:filename
        let l:display = s:ScratchDisplay(l:path)

        call add(l:source, l:display . "\t" . l:filename)
    endfor

    " Preview using bat when available, otherwise cat.
    if executable('bat')
        let l:preview = 'bat --color=always --style=plain --paging=never -- '
                    \ . shellescape(l:dir) . '/{2}'
    else
        let l:preview = 'cat -- ' . shellescape(l:dir) . '/{2}'
    endif

    call fzf#run(fzf#wrap('scratch', {
                \ 'source': l:source,
                \ 'sink*': function('<SID>ScratchListSink'),
                \ 'options': [
                \   '--expect=ctrl-d,ctrl-t,ctrl-x,ctrl-v',
                \   '--delimiter=\t',
                \   '--with-nth=1',
                \   '--preview', l:preview,
                \   '--preview-window=right,50%,wrap',
                \   '--bind=ctrl-/:toggle-preview'
                \ ]
                \ }))
endfunction


" ============================================================================
" Commands and mappings
" ============================================================================

command! ScratchRun       call s:ScratchRun()
command! ScratchNew       call s:ScratchRun()
command! ScratchList      call s:ScratchList()
command! ScratchDeleteAll call s:ScratchDeleteAll()

" Override the default <Space><Space> mapping.
nnoremap <silent> <Space><Space> :ScratchList<CR>


" ============================================================================
" Autocommands
" ============================================================================

augroup ScratchCleanup
    autocmd!
    autocmd BufWipeout * call <SID>ScratchCleanup(str2nr(expand('<abuf>')))
    autocmd VimLeavePre * call <SID>ScratchCleanupAll()
augroup END
