if exists("g:loaded_send2term") || &cp || v:version < 700
    finish
endif
let g:loaded_send2term = 1
let s:parent_path = fnamemodify(expand("<sfile>"), ":p:h:s?/plugin??")

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Default config
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if !exists("g:send2term_paste_file")
    let g:send2term_paste_file = tempname()
endif

if !exists("g:send2term_toggle_default_cmd")
    let g:send2term_toggle_default_cmd = 0
endif

if !exists("g:send2term_preserve_curpos")
    let g:send2term_preserve_curpos = 1
endif

if !exists("g:send2term_flash_duration")
    let g:send2term_flash_duration = 150
endif

if !exists("g:send2term_cmd")
    let g:send2term_cmd = "bash"
endif


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Terminal
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:send2term_term = -1
let s:send2term_bufnr = -1
let s:send2term_cmd = -1

" NVim and VIM8 Terminal Implementation
" =====================================
function! s:TerminalOpen(cmd)
    if has('nvim')
        let current_win = winnr()

        if s:send2term_term == -1 || s:send2term_bufnr == -1
            if exists("&filetype")
                let custom_open = "_TerminalOpen_" . substitute(&filetype, "[.]", "_", "g")
                if exists("*" . custom_open)
                    call call(custom_open, [a:cmd])
                endif
            endif

            " force terminal split to open below current pane
            :exe "set splitbelow"
            execute "split term://" . a:cmd
            let s:send2term_term = b:terminal_job_id
            let s:send2term_bufnr = bufnr('%')
            let s:send2term_cmd = a:cmd

            " Give the terminal a moment to start up so following commands can take effect
            sleep 500m

            " Make terminal scroll to follow output
            :exe "normal G"
            :exe "normal 10\<c-w>_"
        elseif bufwinnr(s:send2term_bufnr) <= 0
            execute "sbuffer " . s:send2term_bufnr

            " Make terminal scroll to follow output
            :exe "normal G"
            :exe "normal 10\<c-w>_"
        endif

        execute current_win .. "wincmd w"
    elseif has('terminal')
        " Keep track of the current window number so we can switch back.
        let current_win = winnr()

        " Open a Terminal with the command running.
        if s:send2term_term == -1
            execute "below split"
            let s:send2term_term = term_start((a:cmd), #{
                        \ term_name: 'send2term',
                        \ term_rows: 10,
                        \ norestore: 1,
                        \ curwin: 1,
                        \ })

        endif

        " Return focus to the original window.
        execute current_win .. "wincmd w"
    endif
endfunction

function! s:TerminalRun()
    let cmd = input("cmd: ", g:send2term_cmd)
    call s:TerminalOpen(cmd)
endfunction

function! s:TerminalToggle()
    if has('nvim')
        if s:send2term_term != -1 && s:send2term_bufnr != -1
            if bufwinnr(s:send2term_bufnr) <= 0
                let current_win = winnr()
                execute "sbuffer " . s:send2term_bufnr

                " Make terminal scroll to follow output
                :exe "normal G"
                :exe "normal 10\<c-w>_"
                execute current_win .. "wincmd w"
            else
                execute "close " . s:send2term_bufnr
            endif
        else
            if g:send2term_toggle_default_cmd == 1
                call s:TerminalOpen(g:send2term_cmd)
            else
                call s:TerminalRun()
            endif
        endif
    else
        echoerr "toggling terminal window only implemented for neovim"
    endif
endfunction

function! s:TerminalClose()
    if has('nvim')
        if s:send2term_term != -1 && s:send2term_bufnr != -1 && bufwinnr(s:send2term_bufnr) > 0
            execute "close " . s:send2term_bufnr
        else
            echoerr "no terminal to close"
        endif
    else
        echoerr "closeing terminal window only implemented for neovim"
    endif
endfunction

function! s:TerminalQuit()
    if has('nvim')
        execute "bd! " . s:send2term_bufnr
        let s:send2term_term = -1
        let s:send2term_bufnr = -1
        let s:send2term_cmd = -1
    else
        echoerr "quiting terminal window only implemented for neovim"
    endif
endfunction

function! s:TerminalSend(text)
    call s:TerminalOpen(g:send2term_cmd)
    if has('nvim')
        "call jobsend(s:send2term_term, a:text . "\<CR>")
        call jobsend(s:send2term_term, a:text)
    elseif has('terminal')
        call term_sendkeys(s:send2term_term, a:text . "\<CR>")
    endif
endfunction


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:SID()
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction

function! s:WritePasteFile(text)
    " could check exists("*writefile")
    call system("cat > " . g:send2term_paste_file, a:text)
endfunction

function! s:_EscapeText(text)
    if exists("&filetype")
        let custom_escape = "_EscapeText_" . substitute(&filetype, "[.]", "_", "g")
        if exists("*" . custom_escape)
            let result = call(custom_escape, [a:text])
        endif
    endif

    " use a:text if the ftplugin didn't kick in
    if !exists("result")
        let result = a:text
    endif

    " return an array, regardless
    if type(result) == type("")
        return [result]
    else
        return result
    endif
endfunction

function! s:Send2TermFlashVisualSelection()
    " Redraw to show current visual selection, and sleep
    redraw
    execute "sleep " . g:send2term_flash_duration . " m"
    " Then leave visual mode
    silent exe "normal! vv"
endfunction

function! s:Send2TermSendOp(type, ...) abort

    let sel_save = &selection
    let &selection = "inclusive"
    let rv = getreg('"')
    let rt = getregtype('"')

    if a:0  " Invoked from Visual mode, use '< and '> marks.
        silent exe "normal! `<" . a:type . '`>y'
    elseif a:type == 'line'
        silent exe "normal! '[V']y"
    elseif a:type == 'block'
        silent exe "normal! `[\<C-V>`]\y"
    else
        silent exe "normal! `[v`]y"
    endif

    call setreg('"', @", 'V')
    call s:Send2TermSend(@")

    " Flash selection
    if a:type == 'line'
        silent exe "normal! '[V']"
        call s:Send2TermFlashVisualSelection()
    endif

    let &selection = sel_save
    call setreg('"', rv, rt)

    call s:Send2TermRestoreCurPos()
endfunction

function! s:Send2TermSendRange() range abort

    let rv = getreg('"')
    let rt = getregtype('"')
    silent execute a:firstline . ',' . a:lastline . 'yank'
    call s:Send2TermSend(@")
    call setreg('"', rv, rt)
endfunction

function! s:Send2TermSendLines(count) abort

    let rv = getreg('"')
    let rt = getregtype('"')

    silent execute "normal! " . a:count . "yy"

    call s:Send2TermSend(@")
    call setreg('"', rv, rt)

    " Flash lines
    silent execute "normal! V"
    if a:count > 1
        silent execute "normal! " . (a:count - 1) . "\<Down>"
    endif
    call s:Send2TermFlashVisualSelection()
endfunction

function! s:Send2TermStoreCurPos()
    if g:send2term_preserve_curpos == 1
        if exists("*getcurpos")
            let s:cur = getcurpos()
        else
            let s:cur = getpos('.')
        endif
    endif
endfunction

function! s:Send2TermRestoreCurPos()
    if g:send2term_preserve_curpos == 1
        call setpos('.', s:cur)
    endif
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Public interface
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:Send2TermSend(text)
    let pieces = s:_EscapeText(a:text)
    for piece in pieces
        call s:TerminalSend(piece)
    endfor
endfunction

function! s:Send2TermOpen() abort
    call inputsave()
    call s:TerminalOpen(g:send2term_cmd)
    call inputrestore()
endfunction

function! s:Send2TermRun() abort
    call inputsave()
    call s:TerminalRun()
    call inputrestore()
endfunction

function! s:Send2TermToggle() abort
    call inputsave()
    call s:TerminalToggle()
    call inputrestore()
endfunction

function! s:Send2TermClose() abort
    call inputsave()
    call s:TerminalClose()
    call inputrestore()
endfunction

function! s:Send2TermQuit() abort
    call inputsave()
    call s:TerminalQuit()
    call inputrestore()
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Setup key bindings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

command -bar -nargs=0 TermRun call s:Send2TermRun()
command -bar -nargs=0 TermOpen call s:Send2TermOpen()
command -bar -nargs=0 TermClose call s:Send2TermClose()
command -bar -nargs=0 TermToggle call s:Send2TermToggle()
command -bar -nargs=0 TermQuit call s:Send2TermQuit()
command -range -bar -nargs=0 TermSend <line1>,<line2>call s:Send2TermSendRange()
command -nargs=+ TermSend1 call s:Send2TermSend(<q-args>)

noremap <SID>Operator :<c-u>call <SID>Send2TermStoreCurPos()<cr>:set opfunc=<SID>Send2TermSendOp<cr>g@

noremap <unique> <script> <silent> <Plug>Send2TermRegionSend :<c-u>call <SID>Send2TermSendOp(visualmode(), 1)<cr>
noremap <unique> <script> <silent> <Plug>Send2TermLineSend :<c-u>call <SID>Send2TermSendLines(v:count1)<cr>
noremap <unique> <script> <silent> <Plug>Send2TermMotionSend <SID>Operator
noremap <unique> <script> <silent> <Plug>Send2TermParagraphSend <SID>Operatorip

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Mappings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if !exists("g:send2term_no_mappings") || !g:send2term_no_mappings
    if !hasmapto('<Cmd>TermToggle', 'n')
        nmap <leader>st <Cmd>TermToggle<CR>
    endif

    if !hasmapto('<Cmd>TermRun', 'n')
        nmap <leader>sr <Cmd>TermRun<CR>
    endif

    if !hasmapto('<Cmd>TermOpen', 'n')
        nmap <leader>so <Cmd>TermOpen<CR>
    endif

    if !hasmapto('<Cmd>TermClose', 'n')
        nmap <leader>sc <Cmd>TermClose<CR>
    endif

    if !hasmapto('<Cmd>TermQuit', 'n')
        nmap <leader>sq <Cmd>TermQuit<CR>
    endif

    if !hasmapto('<Plug>Send2TermRegionSend', 'x')
        xmap <leader>ss  <Plug>Send2TermRegionSend
        xmap <c-e> <Plug>Send2TermRegionSend
    endif

    if !hasmapto('<Plug>Send2TermLineSend', 'n')
        nmap <leader>sl <Plug>Send2TermLineSend
    endif

    if !hasmapto('<Plug>Send2TermParagraphSend', 'n')
        nmap <leader>ss <Plug>Send2TermParagraphSend
        nmap <c-e> <Plug>Send2TermParagraphSend
    endif

    if !hasmapto('<Plug>Send2TermMotionSend', 'n')
        nmap <leader>se <Plug>Send2TermMotionSend
    endif

    imap <c-e> <Esc><Plug>Send2TermParagraphSend<Esc>i<Right>
endif
