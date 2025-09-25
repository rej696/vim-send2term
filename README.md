# vim-send2term #

A Vim/NeoVim plugin for sending selections and lines to a terminal

This plugin was based on
[vim-tidal](https://github.com/tidalcycles/vim-tidal), which was
itself originally based on [vim-slime](https://github.com/jpalardy/vim-slime).

If you are using Vim8 or NeoVim, you can use the native Terminal feature instead
of tmux. Read the Configuration section on how to enable it.

### Commands

These are some of the commands that can be run from Vim command line:

* `:<range>TermSend`: Send a `[range]` of lines. If no range is provided the
  current line is sent.

* `:TermSend1 {text}`: Send a single line of text specified on the command
  line.

* `:TermOpen`: Open a terminal with the default command (provided in g:send2term_cmd)
* `:TermRun`: Open a terminal with a command provided by the user
* `:TermClose`: Close the terminal buffer, while allowing it to be reopened later like `:close`
* `:TermQuit`: Quit the terminal, killing the buffer and any running processes like `:quit`
* `:TermToggle`: if no terminal exists, open a new terminal prompting for a
  command to run. If a terminal is open, close it. if the terminal exists but
  is closed, then show that terminal buffer in a split.


### Default bindings

Using one of these key bindings you can send lines to Send2Term:

* `<c-e>` (Control+E): Send current inner paragraph.
* `<leader>ss`: Send current visually selected block or current inner paragraph
* `<leader>sl`: Send current line
* `<leader>st`: run `:TermToggle`
* `<leader>sr`: run `:TermRun`
* `<leader>so`: run `:TermOpen`
* `<leader>sc`: run `:TermClose`
* `<leader>sq`: run `:TermQuit`

`<c-e>` can be called on either Normal, Visual, Select or Insert mode, so it is
probably easier to type than `<leader>ss`.


## Configure ##

### Command

By default, `vim-send2term` uses `bash` as the command to launch in the terminal.
You can either then run your repl program in the bash window, or specify another command to use with `g:send2term_cmd`.

For example, if you wanted to launch python by default, you could use:

```vim
let g:send2term_cmd = "python3"
```

You could also use `:TermRun` or `:TermToggle` and enter the command in the text input window there

If you want `:TermToggle` to use the default command, rather than
prompting for a command to run, you can do:
```vim
let g:send2term_toggle_default_cmd = 1
```

### Default bindings ###

By default, there are two normal keybindings and one for visual blocks using
your `<leader>` key.  If you don't have one defined, set it on your
`.vimrc` script with `let mapleader=" "`, for example.

If you don't like some of the bindings or want to change them, add this line to
disable them:

```vim
let g:send2term_no_mappings = 1
```

See section Mappings on [plugin/send2term.vim](plugin/send2term.vim) and copy the
bindings you like to your `.vimrc` file and modify them.

### Vim Terminal

On both Vim (version 8 or above) and NeoVim use the native terminal

Open a file, write and send a line of code to send2term, and
the send2term terminal will open in a window below your editor.

Use standard vim window navigation controls to focus the terminal (ie `<C-w> down/up`)

You can learn more about the native Vim terminal here:

https://vimhelp.org/terminal.txt.html

### Miscellaneous ###

When sending a paragraph or a single line, vim-send2term will "flash" the selection
for some milliseconds.  By default duration is set to 150ms, but you can modify
it by setting the `g:send2term_flash_duration` variable.

Write the paste buffer to an external text file:

```vim
let g:send2term_paste_file = "/tmp/send2term_paste_file.txt"
```

For customizing the startup script for defining helper functions, see below.

## License

Refer to the [LICENSE](LICENSE) file
