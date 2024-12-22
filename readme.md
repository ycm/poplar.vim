<h1 align="center">poplar.vim</h1>

<p align="center">🌳 Filetree and pinned files menu using native Vim popups. 📌</p>

[asciinema](https://asciinema.org) (not a screen recording):

![demogif](https://github.com/ycm/poplar.vim/blob/master/demo/demo.gif)

Screenshot:

![demopng](https://github.com/ycm/poplar.vim/blob/master/demo/demo.png)

[NERDTree](https://github.com/preservim/nerdtree) is great but I think popups fit my workflow a lot better. In particular,

- I don't want to manually toggle to show/hide the filetree.
- Esthetically the NERDTree menu dialog is jarring.
- An active NERDTree buffer causes my (default) tabline to display `NERD_tree_tab_x`, which is unhelpful.
- I especially don't enjoy how NERDTree buffers interfere with window splits and sessions.

Popup windows have come a long way since being added in 8.2; this plugin also demonstrates some ways to exploit their functionality, maybe slightly beyond what they were intended to do.

## Features

Poplar offers a filetree that also interacts nicely with a side-by-side **pinned items** menu, similar to NERDTree bookmarks or [harpoon](https://github.com/ThePrimeagen/harpoon/).

Except it's better than vanilla harpoon, since pinned files are dynamically refreshed. For example, if you pin `foo/bar.txt`, and rename `foo/` to `baz/`, Poplar will update the pinned item to `baz/bar.txt`. I think the side-by-side style is better than NERDTree bookmarks also.

Of course Poplar supports the familiar filesystem operations from NERDTree: add, move, rename, delete, chmod, open, open tab, open split, change root, toggle hidden files, copy path, and running arbitrary system commands.

Notably, Poplar implements a very reasonable **input line** that supports:
- familiar cursor navigation keys - `<left>`, `<right>`, `<home>`, `<end>`, `<c-a>`, and `<c-e>`
- moving across `/` characters with `<c-left>` and `<c-right>` to edit filepaths more intuitively
- natural asymmetric scrolling so you can see which characters you're backspacing
- arbitrary multibyte/ambiwidth input (including composing characters)
- pasting instantly (without pasting character by character like some other implementations).

By default, `?` will show current key bindings:

![demohelppng](https://github.com/ycm/poplar.vim/blob/master/demo/demo-help.png)

## Setup

Requires Vim 9+.

Using a package manager like [vim-plug](https://github.com/junegunn/vim-plug):
```vim
Plug 'ycm/poplar.vim'
```

⚠️ For Vim <9.1.850 there was a long-standing bug with vim9 object type inference. This was resolved recently with [this commit](https://github.com/vim/vim/commit/56d45f1b6658ca64857b4cb22f18a18eeefa0f1d), but a number of platforms have not updated yet. So if you are running an earlier version of Vim, please try the `testing` branch:
```vim
Plug 'ycm/poplar.vim', { 'branch': 'testing' }
```

Manual installation:

```sh
mkdir -p ~/.vim/pack/ycm/start && cd ~/.vim/pack/ycm/start
git clone https://github.com/ycm/poplar.vim.git
vim -u NONE -c "helptags poplar.vim/doc" -c q
```

Poplar will write the pinned items list to a file (`.poplar.txt` by default), which means you might want to ignore it:

```sh
echo ".poplar.txt" >> .gitignore
```

Also, `set autochdir` is **not recommended**, as it will render a lot of Poplar's functionality useless.

If East Asian characters are displaying incorrectly, check `&ambiwidth`.

## Configuration

Sample mapping:
```vim
nnoremap <silent> <leader>p :Poplar<cr>
```

Recommended:
```vim
highlight! link PoplarMenu Normal
highlight! link PoplarMenuSel CursorLine
```

It's very easy to configure Poplar. Just declare a dictionary called `g:poplar` in your `.vimrc`, or otherwise ensure it's declared prior to executing `:Poplar`:

```vim
vim9script
g:poplar = {
    keys: {
        SWITCH_WINDOW_L: '<c-h>',
        SWITCH_WINDOW_R: '<c-l>',
    },
    yankreg: '0',
    diropensymb: '▾',
    dirclosedsymb: '▸',
}
```

The equivalent in legacy vimscript:

```vim
let g:poplar = {
\     'keys': {
\         'SWITCH_WINDOW_L': '<c-h>',
\         'SWITCH_WINDOW_R': '<c-l>',
\     },
\     'yankreg': '0',
\     'diropensymb': '▾',
\     'dirclosedsymb': '▸',
\ }
```

Note that if you're okay with the defaults, there's no need to declare the dictionary. Please see `:h poplar` for a full list of configs and their defaults.

Unlike NERDTree, which heavily pollutes the namespace (you can verify this with `:echo g:->keys()->filter('v:val =~ "^NERD"')`), everything Poplar uses is stored in `g:poplar`.

**Colors**

If you have NERDTree colors defined, Poplar will use those. But alternatively you can override them and define your own colors. Below are the highlight groups you can define:

```vim
PoplarMenu
PoplarMenuSel
PoplarTreeDir
PoplarTreeCWD
PoplarTreeFile
PoplarTreeExecFile
PoplarTreeLinkFile
PoplarInputText
PoplarInputCursor
PoplarHelpText
PoplarHelpKey
PoplarPinNotFound
```

Note that Poplar will not automatically add these highlight groups - add them to your namespace only if you want to.
