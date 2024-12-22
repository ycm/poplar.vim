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

Notably, Poplar features an **input line** that supports **arbitrary multibyte/ambiwidth input** (including composing characters) and **pasting instantly** (without pasting character by character like some other implementations).

By default, `?` will show current key bindings:

![demohelppng](https://github.com/ycm/poplar.vim/blob/master/demo/demo-help.png)

## Setup

Requires Vim 9+.

Using a package manager like [vim-plug](https://github.com/junegunn/vim-plug):
```
Plug 'ycm/poplar.vim'
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
```
nnoremap <silent> <leader>p :Poplar<cr>
```

It's very easy to configure Poplar. Just declare a dictionary like the following:

```
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
See `:h poplar` for a full list of configs and their defaults.

Unlike NERDTree, which heavily pollutes the namespace (you can verify this with `:echo g:->keys()->filter('v:val =~ "^NERD"')`), everything Poplar uses is stored in `g:poplar`.

**Colors**

If you have NERDTree colors defined, Poplar will use those. Alternatively you can override them and define your own colors. Below are the highlight groups you can define:

```
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
