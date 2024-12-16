if !has('vim9script') || v:version < 900
    finish
endif

vim9script

import autoload '../autoload/poplar.vim'

hi! PoplarInv cterm=inverse gui=inverse
g:poplar = {input: {}}

command! Poplar poplar.Run()
nnoremap <silent> <leader>p :Poplar<cr>
