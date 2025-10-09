if exists("g:send2term_cmd_python")
    let g:send2term_cmd = g:send2term_cmd_python
else
    let g:send2term_cmd = "python"
endif

let s:python_version = -1
let s:python_version_major = -1
let s:python_version_minor = -1

function! _TerminalOpen_python(cmd)
    if stridx(a:cmd, "python") == -1
        echoerr "Terminal Open command not python"
        return
    endif
    let output = system(a:cmd . " --version")
    let s:python_version = matchstr(output, '\v\d+\.\d+(\.\d+)?')
    let version_parts = split(s:python_version, '\.')
    let s:python_version_major = str2nr(version_parts[0])
    let s:python_version_minor = str2nr(version_parts[1])
endfunction


function! _EscapeText_python(text)
    let lines = split(a:text, "\n")

    " For old versions of python repl, you need to keep the indentation
    if s:python_version_minor < 13
        "echo "python " . s:python_version . " < 3.13"
        let first_line = lines[0]
        let leading_spaces = matchstr(first_line, '^\s*')
        let num_spaces = strchars(leading_spaces)
        for i in range(len(lines))
            let lines[i] = substitute(lines[i], '^\s\{0,' . num_spaces . '}', '', '')
        endfor
    else
        "echo "python " . s:python_version . " >= 3.13"
        for i in range(len(lines))
            let lines[i] = substitute(lines[i], '^\s*', '', '')
        endfor
    endif

    let final_text = join(lines, "\n") . "\n"
    if len(lines) > 1
        let final_text = final_text . "\n"
    endif
    let final_text = substitute(final_text, '\\', '\\\\', 'g')

    return [final_text]
endfunction
