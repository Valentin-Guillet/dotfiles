
if exists("g:loaded_hidden_tags")
    finish
endif
let g:loaded_hidden_tags = 1

if !exists('g:tags_dir')
    let g:tags_dir = $HOME . "/.cache/vim/tags/"
endif

if !isdirectory(g:tags_dir)
    call mkdir(g:tags_dir, 'p')
endif

let s:tab_before_jump = -1
let s:tab_after_jump = -1


function s:GetTagsPath()
    let l:list_files = globpath(g:tags_dir, '*', 0, 1)
    call map(l:list_files, {_, val -> val[strridx(val, '/')+1:]})
    call sort(l:list_files, {a, b -> strlen(a) < strlen(b)})
    let l:curr_file = substitute(expand("%:p:h"), '/', '%', 'g')

    for l:file in l:list_files
        if l:curr_file =~ '^' . l:file
            return g:tags_dir . l:file
        endif
    endfor

    return ""
endfunction

function s:UpdateTagsFile()
    let l:tags_path = s:GetTagsPath()

    if empty(l:tags_path)
        if confirm("Save project tags file for directory " . getcwd() . " ?", "&Yes\n&No") == 2
            echom "Aborted"
            return 0
        endif
        let l:project_path = getcwd()
        let l:tags_file = substitute(getcwd(), '/', '\\\%', 'g')
    else
        let l:raw_tags_file = l:tags_path[strridx(l:tags_path, '/')+1:]
        let l:project_path = substitute(l:raw_tags_file, '%', '/', 'g')
        let l:tags_file = substitute(l:raw_tags_file, '%', '\\%', 'g')
    endif

    " Create the tag file in advance so that GetTagsPath() finds it, even if
    " the background `ctags` command takes time to finish
    silent execute "!touch " . g:tags_dir . l:tags_file
    silent execute "!ctags -Rf " . l:tags_file . " " . l:project_path . " && mv " . l:tags_file . " " . g:tags_dir . " &"
    redraw!
    echom !empty(l:tags_path) ? "Tags updated" : "Tags created"
    return empty(l:tags_path)
endfunction

function s:TagsGoToOpenedTab(tag)
    if empty(tagfiles())
        echohl ErrorMsg | echo "E433: No tags file" | echohl None
        return
    endif

    let l:tag_list = taglist('^' . a:tag . '$')
    if empty(l:tag_list)
        echohl ErrorMsg | echo "E426: tag not found: " . a:tag | echohl None
        return
    endif

    " Tag is in the current file: no need to search through tabs
    let l:dst_file = l:tag_list[0]["filename"]
    if l:dst_file ==# expand('%:p')
        execute "normal! \<C-]>"
        return
    endif

    let l:found_tab_nr = -1
    let l:found_buf_nr = -1
    for l:tab in range(1, tabpagenr('$'))
        for l:buf_nr in tabpagebuflist(l:tab)
            let l:buf_name = bufname(l:buf_nr)
            let l:buf_path = fnamemodify(l:buf_name, ':p')

            if l:dst_file ==# l:buf_path
                let l:found_tab_nr = l:tab
                let l:found_buf_nr = l:buf_nr
                break
            endif
        endfor
        if l:found_tab_nr != -1
            break
        endif
    endfor

    " File not found in any tab
    if l:found_tab_nr == -1
        execute "normal! \<C-]>"
        return
    endif

    " Modify <C-o> and <C-i> targets only when current tab and destination
    " tab are different
    if tabpagenr() != l:found_tab_nr
        let s:tab_before_jump = tabpagenr()
        let s:tab_after_jump = l:found_tab_nr
    endif

    execute l:found_tab_nr . "tabnext"
    execute bufwinnr(bufname(l:found_buf_nr)) . "wincmd w"
    call s:SetTags()
    execute "tag " . a:tag
endfunction

function s:UpTabJumpList()
    if !(0 <= s:tab_before_jump && s:tab_before_jump <= tabpagenr('$'))
        echo "Tab index invalid: active tabs may have changed"
        return
    elseif s:tab_before_jump == tabpagenr()
        echo "Already on target buffer"
        return
    endif

    execute s:tab_before_jump . "tabnext"
endfunction

function s:DownTabJumpList()
    if !(0 <= s:tab_after_jump && s:tab_after_jump <= tabpagenr('$'))
        echo "Tab index invalid: active tabs may have changed"
        return
    elseif s:tab_after_jump == tabpagenr()
        echo "Already on target buffer"
        return
    endif

    execute s:tab_after_jump . "tabnext"
endfunction

function s:SetTags()
    execute "setlocal tags=" . s:GetTagsPath()
endfunction

function s:DeleteTagsFile()
    if empty(&l:tags) | echo "No tag file" | return | endif
    let l:escaped_tags = substitute(&l:tags, '%', '\\%', 'g')
    execute "silent !rm " . l:escaped_tags
    redraw!
    echo "Tags file (" . l:escaped_tags . ") removed"
    call s:SetTags()
endfunction

function s:CleanTagsFiles()
    let l:list_files = globpath(g:tags_dir, '*', 0, 1)
    let l:count = 0
    for l:file in l:list_files
        let l:lines = readfile(l:file, '', 1)
        if empty(l:lines) || l:lines[0] !~ '^!_TAG_'
            continue
        endif
        let l:rel_file = fnamemodify(l:file, ":t")
        let l:dir = substitute(l:rel_file, '%', '/', 'g')
        if !isdirectory(l:dir)
            let l:escaped_file = substitute(l:file, '%', '\\%', 'g')
            execute "silent !rm " . shellescape(l:escaped_file)
            let l:count += 1
        endif
    endfor
    redraw!

    if l:count
        echo l:count . " file" . (l:count > 1 ? 's' : '') . " removed"
    else
        echo "No file to remove"
    endif
endfunction

augroup setTags
    autocmd!

    autocmd BufNewFile,BufRead * call <SID>SetTags()
augroup END


command! -bar TagsFileDelete call <SID>DeleteTagsFile()
command! -bar TagsFileSet call <SID>SetTags()
command! -bar TagsFileClean call <SID>CleanTagsFiles()

nnoremap <silent> <leader>G :if <SID>UpdateTagsFile() \| call <SID>SetTags() \| endif<CR>
nnoremap <silent> <C-]> :call <SID>TagsGoToOpenedTab(expand("<cword>"))<CR>
nnoremap <silent> <leader>] :vsp <CR>:execute "tag " . expand("<cword>")<CR>
nnoremap <silent> <leader>} :tab split<CR>:execute "tag " . expand("<cword>")<CR>
nnoremap <silent> <leader><C-o> :call <SID>UpTabJumpList()<CR>
nnoremap <silent> <leader><C-i> :call <SID>DownTabJumpList()<CR>
