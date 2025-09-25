if exists("g:loaded_send2term") || &cp || v:version < 700
  finish
endif
let g:loaded_send2term = 1
let s:parent_path = fnamemodify(expand("<sfile>"), ":p:h:s?/plugin??")

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Default config
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if !exists("g:send2term_target")
  if has('nvim') || has('terminal')
    let g:send2term_target = "terminal"
  else
    let g:send2term_target = "tmux"
  endif
endif

if !exists("g:send2term_paste_file")
  let g:send2term_paste_file = tempname()
endif

if !exists("g:send2term_default_config")
  let g:send2term_default_config = { "socket_name": "default", "target_pane": ":0.1" }
endif

if !exists("g:send2term_preserve_curpos")
  let g:send2term_preserve_curpos = 1
endif

if !exists("g:send2term_flash_duration")
  let g:send2term_flash_duration = 150
endif

if !exists("g:send2term_prog")
  let g:send2term_ghci = "bash"
endif



"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Tmux
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:TmuxSend(config, text)
  let l:prefix = "tmux -L " . shellescape(a:config["socket_name"])
  " use STDIN unless configured to use a file
  if !exists("g:send2term_paste_file")
    call system(l:prefix . " load-buffer -", a:text)
  else
    call s:WritePasteFile(a:text)
    call system(l:prefix . " load-buffer " . g:send2term_paste_file)
  end
  call system(l:prefix . " paste-buffer -d -t " . shellescape(a:config["target_pane"]))
endfunction

function! s:TmuxPaneNames(A,L,P)
  let format = '#{pane_id} #{session_name}:#{window_index}.#{pane_index} #{window_name}#{?window_active, (active),}'
  return system("tmux -L " . shellescape(b:send2term_config['socket_name']) . " list-panes -a -F " . shellescape(format))
endfunction

function! s:TmuxConfig() abort
  if !exists("b:send2term_config")
    let b:send2term_config = {"socket_name": "default", "target_pane": ":"}
  end

  let b:send2term_config["socket_name"] = input("tmux socket name: ", b:send2term_config["socket_name"])
  let b:send2term_config["target_pane"] = input("tmux target pane: ", b:send2term_config["target_pane"], "custom,<SNR>" . s:SID() . "_TmuxPaneNames")
  if b:send2term_config["target_pane"] =~ '\s\+'
    let b:send2term_config["target_pane"] = split(b:send2term_config["target_pane"])[0]
  endif
endfunction


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Terminal
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:send2term_term = -1

" NVim and VIM8 Terminal Implementation
" =====================================
function! s:TerminalOpen()
  if has('nvim')
    let current_win = winnr()

    if s:send2term_term == -1
        " force terminal split to open below current pane
        :exe "set splitbelow"
        execute "split term://" . g:send2term_prog
        let s:send2term_term = b:terminal_job_id

        " Give send2term a moment to start up so following commands can take effect
        sleep 500m

        " Make terminal scroll to follow output
        :exe "normal G"
        :exe "normal 10\<c-w>_"
    endif

    execute current_win .. "wincmd w"
  elseif has('terminal')
    " Keep track of the current window number so we can switch back.
    let current_win = winnr()

    " Open a Terminal with GHCI with send2term booted.
    if s:send2term_term == -1
      execute "below split"
      let s:send2term_term = term_start((g:send2term_prog), #{
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

function! s:TerminalSend(config, text)
  call s:TerminalOpen()
  if has('nvim')
    call jobsend(s:send2term_term, a:text . "\<CR>")
  elseif has('terminal')
    call term_sendkeys(s:send2term_term, a:text . "\<CR>")
  endif
endfunction

" These two are unnecessary AFAIK.
function! s:TerminalPaneNames(A,L,P)
endfunction
function! s:TerminalConfig() abort
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:SID()
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun

function! s:WritePasteFile(text)
  " could check exists("*writefile")
  call system("cat > " . g:send2term_paste_file, a:text)
endfunction

function! s:_EscapeText(text)
  if exists("&filetype")
    let custom_escape = "_EscapeText_" . substitute(&filetype, "[.]", "_", "g")
    if exists("*" . custom_escape)
      let result = call(custom_escape, [a:text])
    end
  end

  " use a:text if the ftplugin didn't kick in
  if !exists("result")
    let result = a:text
  end

  " return an array, regardless
  if type(result) == type("")
    return [result]
  else
    return result
  end
endfunction

function! s:Send2TermGetConfig()
  if !exists("b:send2term_config")
    if exists("g:send2term_default_config")
      let b:send2term_config = g:send2term_default_config
    else
      call s:Send2TermDispatch('Config')
    end
  end
endfunction

function! s:Send2TermFlashVisualSelection()
  " Redraw to show current visual selection, and sleep
  redraw
  execute "sleep " . g:send2term_flash_duration . " m"
  " Then leave visual mode
  silent exe "normal! vv"
endfunction

function! s:Send2TermSendOp(type, ...) abort
  call s:Send2TermGetConfig()

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
  call s:Send2TermGetConfig()

  let rv = getreg('"')
  let rt = getregtype('"')
  silent execute a:firstline . ',' . a:lastline . 'yank'
  call s:Send2TermSend(@")
  call setreg('"', rv, rt)
endfunction

function! s:Send2TermSendLines(count) abort
  call s:Send2TermGetConfig()

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
  call s:Send2TermGetConfig()

  let pieces = s:_EscapeText(a:text)
  for piece in pieces
    call s:Send2TermDispatch('Send', b:send2term_config, piece)
  endfor
endfunction

function! s:Send2TermConfig() abort
  call inputsave()
  call s:Send2TermDispatch('Config')
  call inputrestore()
endfunction

" delegation
function! s:Send2TermDispatch(name, ...)
  let target = substitute(tolower(g:send2term_target), '\(.\)', '\u\1', '') " Capitalize
  return call("s:" . target . a:name, a:000)
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Setup key bindings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

command -bar -nargs=0 Send2TermConfig call s:Send2TermConfig()
command -range -bar -nargs=0 Send2TermSend <line1>,<line2>call s:Send2TermSendRange()
command -nargs=+ Send2TermSend1 call s:Send2TermSend(<q-args>)

noremap <SID>Operator :<c-u>call <SID>Send2TermStoreCurPos()<cr>:set opfunc=<SID>Send2TermSendOp<cr>g@

noremap <unique> <script> <silent> <Plug>Send2TermRegionSend :<c-u>call <SID>Send2TermSendOp(visualmode(), 1)<cr>
noremap <unique> <script> <silent> <Plug>Send2TermLineSend :<c-u>call <SID>Send2TermSendLines(v:count1)<cr>
noremap <unique> <script> <silent> <Plug>Send2TermMotionSend <SID>Operator
noremap <unique> <script> <silent> <Plug>Send2TermParagraphSend <SID>Operatorip
noremap <unique> <script> <silent> <Plug>Send2TermConfig :<c-u>Send2TermConfig<cr>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Mappings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if !exists("g:send2term_no_mappings") || !g:send2term_no_mappings
  if !hasmapto('<Plug>Send2TermConfig', 'n')
    nmap <buffer> <leader>sc <Plug>Send2TermConfig
  endif

  if !hasmapto('<Plug>Send2TermRegionSend', 'x')
    xmap <buffer> <localleader>s  <Plug>Send2TermRegionSend
    xmap <buffer> <c-e> <Plug>Send2TermRegionSend
  endif

  if !hasmapto('<Plug>Send2TermLineSend', 'n')
    nmap <buffer> <localleader>ss  <Plug>Send2TermLineSend
  endif

  if !hasmapto('<Plug>Send2TermParagraphSend', 'n')
    nmap <buffer> <localleader>ss <Plug>Send2TermParagraphSend
    nmap <buffer> <c-e> <Plug>Send2TermParagraphSend
  endif

  imap <buffer> <c-e> <Esc><Plug>Send2TermParagraphSend<Esc>i<Right>
endif
