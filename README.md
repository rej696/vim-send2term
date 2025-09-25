# vim-send2term #

A Vim/NeoVim plugin for sending selections and lines to a terminal

This plugin was based on [vim.send2term](https://github.com/send2termcycles/vim-send2term), which was itself originally based on
[vim-slime](https://github.com/jpalardy/vim-slime).

![](http://i.imgur.com/frOLFFI.gif)

If you are using Vim8 or NeoVim, you can use the native Terminal feature instead
of tmux. Read the Configuration section on how to enable it.


### Commands

These are some of the commands that can be run from Vim command line:

* `:<range>Send2TermSend`: Send a `[range]` of lines. If no range is provided the
  current line is sent.

* `:Send2TermSend1 {text}`: Send a single line of text specified on the command
  line.

* `:Send2TermConfig`: Configure tmux socket name and target pane

* `:Send2TermSilence [num]`: Silence stream number `[num]` by sending `d[num]
  silence`.

* `:Send2TermPlay [num]`: Send first ocurrence of stream number `[num`] from the
  current cursor position.

* `:Send2TermHush`: Silences all streams by sending `hush`.

* `:Send2TermGenerateCompletions {path}`: Generate dictionary for Dirt-Samples
  completion (path is optional).

### Default bindings

Using one of these key bindings you can send lines to Send2Term:

* `<c-e>` (Control+E), `<localleader>ss`: Send current inner paragraph.
* `<localleader>s`: Send current line or current visually selected block.

`<c-e>` can be called on either Normal, Visual, Select or Insert mode, so it is
probably easier to type than `<localleader>ss` or `<localleader>s`.

There are other bindings to control Send2Term like:

* `<localleader>s[num]`: Call `:Send2TermPlay [num]`
* `<localleader>[num]`: Call `:Send2TermSilence [num]`
* `<localleader>h`, `<c-h>`: Call `:Send2TermHush`

#### About `<localleader>`

The `<leader>` key is a special key used to perform commands with a sequence of
keys.  The `<localleader>` key behaves as the `<leader>` key, but is *local* to
a buffer.  In particular, the above bindings only work in buffers with the
"send2term" file type set, e.g. files whose file type is `.send2term`

By default, there is no `<localleader>` set.  To define one, e.g. for use with
a comma (`,`), write this on your `.vimrc` file:

```vim
let maplocalleader=","
```

Reload your configuration (or restart Vim), and after typing `,ss` on a few
lines of code, you should see those being copied onto the Send2Term interpreter on
the lower pane.


## Configure ##

### Program

By default, `vim-send2term` uses bash as the program to launch in the terminal.
You can either then run your repl program in the bash window, or specify another command to use with `g:send2term_prog`.

For example, if you wanted to launch python, you could use:

```vim
let g:send2term_prog = "python3"
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

On both Vim (version 8 or above) and NeoVim, the default target in which we boot
Send2Term with GHCi is the native terminal.

While it is the default, it can also be specified manually with the following:

```vim
let g:send2term_target = "terminal"
```

Open a file, write and send a line of code to send2term, and
the send2term terminal will open in a window below your editor.

Use standard vim window navigation controls to focus the terminal (ie `<C-w> down/up`)

You can learn more about the native Vim terminal here:

https://vimhelp.org/terminal.txt.html

### tmux (alternative to Vim terminal)

Before Vim had native terminal support, this plugin provided a "tmux" target in
order to allow for multiplexing the user's terminal via the 3rd party CLI tool.
If you have `tmux` installed and you wish to use it instead of the native Vim
terminal, you can enable this target with the following:

```vim
let g:send2term_target = "tmux"
```

This target will be enabled automatically in the case that the version of Vim in
use does not have native terminal support.

You can configure tmux socket name and target pane by typing `<leader>sc`
or `:Send2TermConfig`.  This will prompt you first for the socket name, then for
the target pane.

About the target pane:

* `":"` means current window, current pane (a reasonable default)
* `":i"` means the ith window, current pane
* `":i.j"` means the ith window, jth pane
* `"h:i.j"` means the tmux session where h is the session identifier (either
  session name or number), the ith window and the jth pane

When you exit Vim you will lose that configuration. To make this permanent, set
`g:send2term_default_config` on your `.vimrc`.  For example, suppose you want to run
Send2Term on a tmux session named `omg`, and the terminal will be running
on the window 1 and pane 0.  In that case you would need to add this line:

```vim
let g:send2term_default_config = {"socket_name": "default", "target_pane": "omg:1.0"}
```

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
