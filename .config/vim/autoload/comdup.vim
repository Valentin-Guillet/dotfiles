function! comdup#CommentDuplicate(type)
    let b:ComDup_pos[1] += line("']") - line("'[") + 1
    call s:CopyAndComment('end', b:ComDup_pos)
    unlet! b:ComDup_pos
endfunction

function! comdup#DuplicateComment(type)
    call s:CopyAndComment('start', b:ComDup_pos)
    unlet! b:ComDup_pos
endfunction

function! s:CopyAndComment(target, cur_pos)
    let l:start_line = getpos("'[")[1]
    let l:end_line = getpos("']")[1]
    let l:target_line = (a:target == 'start' ? l:start_line - 1 : l:end_line)

    let l:lines = getline(l:start_line, l:end_line)
    execute l:start_line . "," . l:end_line . "Commentary"
    call append(l:target_line, l:lines)

    call setpos('.', a:cur_pos)
endfunction
