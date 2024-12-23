if !has('vim9script') || v:version < 900
    finish
endif

vim9script noclear

if g:->get('loaded_poplar', false)
    finish
endif
g:loaded_poplar = true

import autoload '../autoload/poplar.vim'

highlight! PoplarInv cterm=inverse gui=inverse

command! Poplar poplar.Run()
