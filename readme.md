<h1 align="center">poplar.vim</h1>

<p align="center">🌳 Filetree and pinned files menu using native Vim popups. 📌</p>

[asciinema](https://asciinema.org) (not a screen recording):

![demogif](https://github.com/ycm/poplar.vim/blob/master/demo/demo.gif)

Screenshot showing `git status`:

![demopng](https://github.com/ycm/poplar.vim/blob/master/demo/demo.png)

[NERDTree](https://github.com/preservim/nerdtree) is great but I think popups fit my workflow a lot better. In particular,

- I don't want to manually toggle to show/hide the filetree.
- Esthetically the NERDTree menu dialog is jarring.
- An active NERDTree buffer causes my (default) tabline to display `NERD_tree_tab_x`, which is unhelpful.
- I especially don't enjoy how NERDTree buffers interfere with window splits and sessions.

Popup windows have come a long way since being added in 8.2; this plugin also demonstrates some ways to exploit their functionality, maybe slightly beyond what they were intended to do.

The goal of Poplar is to provide a good-looking, minimally intrusive drop-in replacement to NERDTree that interacts well with git repos, offers a great deal of customization, but requires very little configuration to get started.

## Features

```vim
:Poplar
:PoplarPin
:PoplarPin {file}
```

Poplar offers a filetree that also interacts nicely with a side-by-side **pinned items** menu, similar to NERDTree bookmarks or [harpoon](https://github.com/ThePrimeagen/harpoon/).

Except it's better than vanilla harpoon, since pinned files are dynamically refreshed. For example, if you pin `foo/bar.txt`, and rename `foo/` to `baz/`, Poplar will update the pinned item to `baz/bar.txt`. I think the side-by-side style is better than NERDTree bookmarks also.

Of course Poplar supports the familiar filesystem operations from NERDTree: add, move, rename, delete, chmod, open, open tab, open split, change root, toggle hidden files, copy path, and running arbitrary system commands. Poplar can also show the `git status` of files in your working tree. It even tries to use `git mv` and `git rm` to rename and delete nodes when possible (you can disable this behavior).

Notably, Poplar implements a very reasonable **input line** that supports:
- familiar cursor navigation keys - `<left>`, `<right>`, `<home>`, `<end>`, `<c-a>`, and `<c-e>`
- moving across `/` characters with `<c-left>` and `<c-right>` to edit filepaths more intuitively
- natural asymmetric scrolling so you can see which characters you're backspacing
- arbitrary multibyte/ambiwidth input (including composing characters)
- pasting instantly (without pasting character by character like some other implementations)

By default, `?` will show current key bindings:

![demohelppng](https://github.com/ycm/poplar.vim/blob/master/demo/demo-help.png)

## Setup

Requires **Vim 9.1+**.

**Warning**: it appears 9.1.1014 introduced a bug and that was reverted in 9.1.1044. It seems between these versions Poplar will not work.

My testing goes back to 9.1.346. Vim builds on Homebrew (macOS), MSYS2 (Windows), and package managers on most major Linux distros are 9.1.7xx or higher as of writing, so if your Vim is up-to-date then Poplar should work fine. Slightly earlier patches *may* work. Vim 9.0 will definitely *not* work, since there were simply too many class/object features that weren't implemented back then.

Using a package manager like [vim-plug](https://github.com/junegunn/vim-plug):
```vim
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
```vim
nnoremap <silent> <leader>p <cmd>Poplar<cr>
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
    showgit: true,
    giticons: {
        staged: '+',
        renamed: '[R]'
    }
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
\     'showgit': 1,
\     'giticons': {
\         'staged': '+',
\         'renamed': '[R]'
\     }
\ }
```

Note that if you're okay with the defaults, there's no need to declare the dictionary. Everything has defaults/fallbacks. Please see `:h poplar` for a full list of configs and their defaults.

Unlike NERDTree, which heavily pollutes the namespace (you can verify this with `:echo g:->keys()->filter('v:val =~ "^NERD"')`), everything Poplar uses is stored in `g:poplar`.

**Colors**

If you have NERDTree colors defined, Poplar will try to use those. But alternatively you can override them and define your own colors. Below are the highlight groups you can define:

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
PoplarGitStaged
PoplarGitModified
PoplarGitRenamed
PoplarGitUntracked
PoplarGitIgnored
PoplarGitUnknown
PoplarGitMultiple
```

Note that Poplar will not automatically add these highlight groups and prefer fallbacks instead, which helps avoid cluttering the `:highlight` namespace.

## Upcoming features

- [ ] jump between filetree node siblings.
- [ ] possibly fuzzy file finding, if I get around to it.
