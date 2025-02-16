if !has('vim9script') || v:version < 901
    finish
endif

vim9script noclear

if has('patch-9.1.1014') && !has('patch-9.1.1044')
    # apparently a nested import bug
    finish
endif

if g:->get('loaded_poplar', false)
    finish
endif
g:loaded_poplar = true

import autoload '../autoload/poplar.vim'

highlight! PoplarInv cterm=inverse gui=inverse

command! Poplar poplar.Run()
command! -nargs=? -complete=file PoplarPin poplar.PinFile(<f-args>)
