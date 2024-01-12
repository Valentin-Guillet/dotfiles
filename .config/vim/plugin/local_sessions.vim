" This plugin allows the user to define a folder-wise session (buffers, tabs,
" views, folds...) that is kept in a hidden folder, by default in
" $XDG_STATE_HOME/vim/sessions/

if exists("g:loaded_local_sessions")
    finish
endif
let g:loaded_local_sessions = 1

if !exists('g:local_sessions_dir')
    let g:local_sessions_dir = $XDG_STATE_HOME . "/vim/sessions/"
endif

if !isdirectory(g:local_sessions_dir)
    call mkdir(g:local_sessions_dir, 'p')
endif

if !exists('g:session_default_name')
    let g:session_default_name = "main"
endif

let s:sep = (has("win32") || has("win64")) ? '\' : '/'


" ... arg is used for autocompletion
function g:GetSessionNames(...)
    let l:list_files = globpath(g:local_sessions_dir, '*', 0, 1)
    call map(l:list_files, {_, val -> val[strridx(val, s:sep)+1:]})
    call sort(l:list_files, {a, b -> strlen(a) < strlen(b)})
    let l:curr_path = substitute(getcwd(), s:sep, '%', 'g')
    let l:curr_path = substitute(l:curr_path, ':', '%', 'g')  " Remove drive separator on Windows

    let l:paths = []
    for l:file in l:list_files
        let l:session_dir = l:file[:strridx(l:file, '#')-1]
        if l:curr_path == l:session_dir
            let l:paths += [l:file[strridx(l:file, '#')+1:]]
        endif
    endfor

    if a:0 > 1 && !empty(a:1)
        let l:paths = filter(l:paths, 'v:val =~ "^" . a:1')
    endif

    return l:paths
endfunction

function s:GetSessionName(name, default=0)
    let l:session_names = GetSessionNames()
    if empty(l:session_names) | echo "No session exist in this directory" | return "" | endif
    if !empty(a:name)
        if index(l:session_names, a:name) == -1
            echo "No such session in this directory"
            return ""
        endif
        let l:session_name = a:name
    else
        if len(l:session_names) == 1
            let l:session_name = l:session_names[0]
        else
            let l:session_name = s:ChooseSessionName()
            if a:default
                if empty(l:session_name) | let l:session_name = g:session_default_name | endif
            else
                redraw
                echo "Aborted"
            endif
        endif
    endif

    return l:session_name
endfunction

function s:ChooseSessionName()
    call inputsave()
    let l:choice = input("Enter session name: ", '', "customlist,g:GetSessionNames")
    call inputrestore()
    return l:choice
endfunction

function s:SaveSession(name="")
    if !empty(a:name)
        let l:session_name = a:name
    elseif !exists("g:session_name")
        let l:session_name = s:ChooseSessionName()
        if empty(l:session_name) | let l:session_name = g:session_default_name | endif
    else
        let l:session_name = g:session_name
    endif

    let l:session_file = substitute(getcwd(), s:sep, '\\\%', 'g')
    let l:session_file = g:local_sessions_dir . substitute(l:session_file, ':', '\\\%', 'g')
    let l:session_file .= "\\#" . l:session_name

    " On Windows, vim can't source a file containing "%vim%" in it (probably
    " because of environment variable expansion ?)
    " We thus prevent all session creation in a path containing a "vim"
    " directory
    if s:sep == '\' && stridx(l:session_file, "\\%vim\\%") != -1
        echoerr "Sorry, can't create a session in a subdirectory of a directory only named \"vim\""
        return 0
    endif

    if (!exists("g:session_name") || !empty(a:name)) &&
                \ filereadable(substitute(l:session_file, '\\', '', 'g')) &&
                \ confirm("A session file with the name \"" . l:session_name . "\" already exists. Do you want to overwrite ?", "&Yes\n&No") == 2
        echo "Aborted"
        return 0
    endif

    execute "mksession! " . l:session_file

    redraw
    if exists("g:session_name") && empty(a:name)
        echom "Session \"" . l:session_name . "\" saved !"
    else
        echom "Session \"" . l:session_name . "\" saved in file " . l:session_file
    endif
    let g:session_name = l:session_name
    return 1
endfunction

function s:OpenSession(name="")
    let l:session_name = s:GetSessionName(a:name, 1)
    if empty(l:session_name) | return 1 | endif

    if exists("g:session_name")
        if l:session_name ==# g:session_name
            redraw
            echo "Session already opened"
            return 1
        else
            call s:CloseSession()
        endif
    endif

    let l:curr_path = substitute(getcwd(), s:sep, '%', 'g')
    let l:curr_path = substitute(l:curr_path, ':', '%', 'g')
    let l:session_file = g:local_sessions_dir . s:sep . l:curr_path . '#' . l:session_name

    if !filereadable(l:session_file) | redraw | echo "No such session in this directory" | return | endif

    let g:session_name = l:session_name
    execute "source " . fnameescape(l:session_file)
    redraw!
    echom "Session " . l:session_name . " loaded"
endfunction

function s:CloseSession()
    if !exists("g:session_name") | echo "No opened session" | return | endif

    if !s:SaveSession("") | return 1 | endif
    unlet g:session_name

    %bdelete
endfunction

function s:DeleteSessionFile(name="")
    let l:session_name = s:GetSessionName(a:name, 0)
    if empty(l:session_name) | return 1 | endif

    if exists("g:session_name") && l:session_name ==# g:session_name
        unlet g:session_name
        %bdelete
    endif

    let l:curr_path = substitute(getcwd(), s:sep, '%', 'g')
    let l:curr_path = substitute(l:curr_path, ':', '%', 'g')
    let l:session_file = g:local_sessions_dir . s:sep . l:curr_path . '#' . l:session_name

    if !filereadable(l:session_file) | redraw | echo "No local session file" | return | endif

    call delete(l:session_file)
    echom "Local session file (" . l:session_file . ") removed"
endfunction

function s:ListSessions()
    let l:session_names = GetSessionNames()
    call sort(l:session_names)
    for l:name in l:session_names
        let l:star = (get(g:, "session_name", "") == l:name ? "*" : "")
        echom " - " . l:name . l:star
    endfor
endfunction

function s:CleanSessionFiles()
    let l:list_files = globpath(g:local_sessions_dir, '*', 0, 1)
    let l:count = 0
    for l:file in l:list_files
        let l:rel_file = fnamemodify(l:file, ":t")
        let l:dir = substitute(l:rel_file, '%%', ':/', 'g')  " Drive separator on Windows
        let l:dir = substitute(l:dir, '%', '/', 'g')
        let l:dir = l:dir[:strridx(l:dir, '#')-1]
        if !isdirectory(l:dir)
            call delete(l:file)
            let l:count += 1
        endif
    endfor
    redraw!

    if l:count
        echom l:count . " file" . (l:count > 1 ? 's' : '') . " removed"
    else
        echom "No file to remove"
    endif
endfunction

function s:AutoOpenSession()
    let l:session_names = GetSessionNames()
    if empty(l:session_names) | return | endif

    call sort(l:session_names)
    if len(l:session_names) == 1
        let l:choice = confirm("A vim session has been found, do you want to open it ?", "&Yes\n&No", 1)
    else
        echo "Multiple vim sessions have been found."
        let l:choice = confirm("Do you want to open one ?", "&Yes\n&No", 1)
        redraw
        if l:choice == 1
            let &cmdheight = len(l:session_names) + 2
            echo "Existing sessions:\n" . join(map(l:session_names, '"- " . v:val'), "\n") . "\n"
            let &cmdheight = 1
        endif
    endif
    if l:choice == 1 | call s:OpenSession() | endif
endfunction

function s:ChangeDirSession()
    " We need `mv` and `sed` command to call this function,
    " so abort if on Windows
    if !has("unix") | echo "Can't do that on Windows" | return | endif

    let l:list_files = globpath(g:local_sessions_dir, '*', 0, 1)
    call map(l:list_files, {_, val -> val[strridx(val, s:sep)+1:]})
    call sort(l:list_files, {a, b -> strlen(a) < strlen(b)})

    if empty(l:list_files)
        echo "No session files !"
        return 1
    endif

    let l:list_paths_with_dup = map(copy(l:list_files), 'v:val[:strridx(v:val, "#")-1]')
    let l:list_paths = []
    for path in l:list_paths_with_dup
        if index(l:list_paths, path) == -1
            let l:list_paths += [path]
        endif
    endfor
    let l:display_paths = map(copy(l:list_paths), 'substitute(v:val, "\%\%", ":/", "g")')
    let l:display_paths = map(copy(l:display_paths), 'substitute(v:val, "\%", "/", "g")')
    let l:display_paths = map(copy(l:display_paths), 'substitute(v:val, $HOME, "~", "g")')
    let l:display_paths = map(l:display_paths, {key, val -> string(key+1) . ". " . val})

    let &cmdheight = len(l:list_paths) + 2
    echo "Existing session paths:\n" . join(l:display_paths, "\n") . "\n"
    let &cmdheight = 1
    call inputsave()
    let l:choice = input("Which folder do you want to import ? ")
    call inputrestore()

    if l:choice !~# '^\d\+$' || str2nr(l:choice) < 1 || len(l:list_paths) < str2nr(l:choice)
        echo "\nInvalid choice !"
        return 1
    endif

    let l:old_sess_path = l:list_paths[l:choice - 1]
    let l:new_sess_path = substitute(getcwd(), ':', '%', 'g')
    let l:new_sess_path = substitute(l:new_sess_path, s:sep, '%', 'g')

    if l:old_sess_path == l:new_sess_path
        echo "\nTrying to move session file to the same place !"
        return 1
    endif

    for l:file in l:list_files
        if stridx(l:file, l:old_sess_path . "#") >= 0
            let l:new_file = substitute(l:file, l:old_sess_path, l:new_sess_path, '')

            let l:path_in_session_file = substitute(l:new_sess_path, "\%", "/", "g")
            let l:path_in_session_file = substitute(l:path_in_session_file, $HOME, "~", "g")
            let l:path_in_session_file = fnameescape(l:path_in_session_file)

            let l:old_path = g:local_sessions_dir . fnameescape(l:file)
            let l:new_path = g:local_sessions_dir . fnameescape(l:new_file)

            execute "silent !mv " . shellescape(l:old_path) . " " . shellescape(l:new_path)
            execute "silent !sed -i 's;^cd .*$;cd " . l:path_in_session_file . ";' " . shellescape(l:new_path)
            redraw!
            echom "Renaming " . l:file . " in " . l:new_file
        endif
    endfor
endfunction


augroup localSession
    autocmd!

    autocmd VimEnter * nested if len(v:argv) == 1 | call s:AutoOpenSession() | endif
augroup END


command! -nargs=? -bar SessionSave call <SID>SaveSession(<f-args>)
command! -nargs=? -bar SessionOpen call <SID>OpenSession(<f-args>)
command! -bar SessionClose call <SID>CloseSession()
command! -nargs=? -bar SessionDelete call <SID>DeleteSessionFile(<f-args>)
command! -bar SessionClean call <SID>CleanSessionFiles()
command! -bar SessionList call <SID>ListSessions()
command! -bar SessionChDir call <SID>ChangeDirSession()

nnoremap <leader>ss :SessionSave<CR>
nnoremap <leader>so :SessionOpen<CR>
nnoremap <leader>sc :SessionClose<CR>
nnoremap <leader>sl :SessionList<CR>
