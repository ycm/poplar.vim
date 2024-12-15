vim9script

# Mockup:
#
# ┌ poplar ─────────────────────────┬ pinned ─────────────────────────┐
# │ </home/ycm/.../>                │   dir2/dir3/file1.txt           │
# │ > dir1                          │ > dir2/dir3/file2.txt           │
# │ > dir2                          │   file3.txt                     │
# │    v dir3                       │                                 │
# │        file1.txt                │                                 │
# │        file2.txt                │                                 │
# │    file3.txt                    │                                 │
# ├─────────────────────────────────┴─────────────────────────────────┤
# │ PROMPT > enter text here                                          │
# ╰───────────────────────────────────────────────────────────────────╯
# 

import autoload '../autoload/poplar.vim'

command! Poplar poplar.Run()
nnoremap <silent> <leader>p :Poplar<cr>
