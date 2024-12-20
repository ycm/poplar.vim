vim9script

import './basewindow.vim'
import './filetree.vim'
import './inputline.vim'

export class TreeWindow extends basewindow.BaseWindow
    var _tree: filetree.FileTree

    def new(this._on_left,
            this._CallbackSwitchFocus,
            this._CallbackExit)
        this._tree = filetree.FileTree.new(getcwd())
        this._tree.ToggleDir(this._tree.root)
        this._InitHelpText()
    enddef


    def InitLines()
        this.SetLines(this._tree.GetPrettyFormatLines())
    enddef


    def _SpecificFilter(key: string): bool
        var idx = this._show_help
                ? this._id->getcurpos()[1] - 1 - this._helptext->len()
                : this._id->getcurpos()[1] - 1
        if idx >= 0 && this._show_modify_mode
            var node = this._tree.GetNodeAtDisplayIndex(idx)
            if key == 'a'
                var starting_text = node.path->isdirectory()
                        ? $'{node.path}/'
                        : $"{node.path->fnamemodify(':h')}/"
                inputline.Open(starting_text,
                               'add a node (dirs end with /)',
                               this._CallbackAddNode,
                               this.ToggleModifyMode)
            elseif key == 'm'
                if node.path == getcwd()
                    this._LogErr('cannot modify cwd.')
                    this.ToggleModifyMode()
                    return false
                endif
                inputline.Open(node.path, 'move/rename node',
                               function(this._CallbackMoveNode, [node.path]),
                               this.ToggleModifyMode)
            elseif key == 'd'
                if node.path == getcwd()
                    this._LogErr('cannot modify cwd.')
                    this.ToggleModifyMode()
                    return false
                endif
                inputline.Open('', $"delete {node.path}? 'yes' to confirm",
                               function(this._CallbackDeleteNode, [node.path]),
                               this.ToggleModifyMode)
            endif
        elseif idx >= 0 && key ==? '<cr>' # ------------------------------ {{{
            var node = this._tree.GetNodeAtDisplayIndex(idx)
            if node.path->isdirectory()
                this._tree.ToggleDir(node)
                this.SetLines(this._tree.GetPrettyFormatLines())
            else
                execute $'drop {node.path->fnamemodify(':~:.')}'
                return this._CallbackExit()
            endif
        elseif idx >= 0 && ['i', 't', 'v']->index(key) >= 0
            var node = this._tree.GetNodeAtDisplayIndex(idx)
            if !node.path->isdirectory()
                var cmd = {'i': 'split', 'v': 'vsplit', 't': 'tab drop'}
                execute $'{cmd[key]} {node.path->fnamemodify(':~:.')}'
                return this._CallbackExit()
            endif
        elseif idx >= 0 && key == 'm'
            this.ToggleModifyMode()
        elseif idx >= 0 && key == 'c'
            var node = this._tree.GetNodeAtDisplayIndex(idx)
            this._tree.ChangeRoot(node)
            this.SetLines(this._tree.GetPrettyFormatLines())
        elseif key == 'I'
            this._tree.ToggleHidden()
            this.SetLines(this._tree.GetPrettyFormatLines())
        elseif key == 'u'
            this._tree.RaiseRoot()
            this._tree.HardRefresh()
            this.SetLines(this._tree.GetPrettyFormatLines())
        elseif key == 'C'
            this._tree.ResetRootToCwd()
            this.SetLines(this._tree.GetPrettyFormatLines())
        elseif key == 'R'
            this._tree.HardRefresh()
            this.SetLines(this._tree.GetPrettyFormatLines())
        elseif key == '?'
            this._show_help = !this._show_help
            this.SetLines(this._lines, false)
            if this._show_help
                ':noa call cursor(1, 1)'->win_execute(this._id)
            else
                var lnum = [
                    1, this._id->getcurpos()[1] - this._helptext->len()
                ]->max()
                $':noa call cursor({lnum}, 1)'->win_execute(this._id)
            endif # ------------------------------------------------------ }}}
        endif
        return true
    enddef


    def _CallbackInputLineEnter(text: string)
        this._Log($'placeholder received <{text}>')
    enddef


    def _CallbackDeleteNode(path: string, confirm: string) # {{{
        if confirm->trim() !=? 'yes'
            this._Log($'node deletion aborted.')
            return
        endif
        if path->isdirectory()
            if path->delete('d') == 0
                this._Log($'deleted directory {path}.')
            else
                this._LogErr($'could not delete directory {path}.')
            endif
        else
            if path->delete() == 0
                var winids = path->bufnr()->win_findbuf()
                for winid in winids
                    $':noa | q!'->win_execute(winid)
                endfor
                if winids == []
                    this._Log($'deleted file {path}.')
                else
                    this._Log($'deleted file {path} and removed {winids->len()} windows.')
                endif
            else
                this._LogErr($'could not delete file: {path}.')
            endif
        endif
        this._tree.HardRefresh()
        this.SetLines(this._tree.GetPrettyFormatLines())
    enddef # }}}


    def _CallbackMoveNode(from: string, to: string) # {{{
        var dest = to->trim()
        if dest == ''
            this._Log('operation aborted.')
            return
        elseif from->isdirectory()
            if dest[-1] != '/'
                dest = dest .. '/'
            endif
            if rename(from, dest) == -1
                this._LogErr($'failed to move directory {from}.')
            else
                var bufs = getbufinfo()
                        ->filter((_, b) => b.name =~ $'^{from}/')
                        ->mapnew((_, b) => [b.bufnr, b.name[from->len() + 1 :]])
                var wins_replaced = 0
                for [bufnr, basename] in bufs
                    echomsg $'{bufnr}: is {basename}'
                    for winid in bufnr->win_findbuf()
                        $':noa | edit! {dest}{basename}'->win_execute(winid)
                        ++wins_replaced
                    endfor
                endfor
                if wins_replaced == 0
                    this._Log($'renamed directory to {dest}.')
                else
                    this._Log($'renamed directory to {dest} and switched buffers in {wins_replaced} windows.')
                endif
            endif
        elseif dest->filereadable()
            this._LogErr($'file already exists: {dest}.')
            return
        else
            if dest[-1] == '/'
                try
                    mkdir(dest, 'p')
                catch /E739/
                endtry
                dest = dest .. from->fnamemodify(':t')
            else
                try
                    mkdir(dest->fnamemodify(':h'))
                catch /E739/
                endtry
            endif
            if rename(from, dest) == -1
                this._LogErr($'failed to move file from {from} to {dest}.')
            else
                var winids = from->bufnr()->win_findbuf()
                dest = dest->fnamemodify(':~:.')
                for winid in winids
                    $':noa | edit! {dest}'->win_execute(winid)
                endfor
                if winids == []
                    this._Log($'moved file to {dest}.')
                else
                    this._Log($'moved file to {dest} and switched buffer(s) in {winids->len()} windows.')
                endif
            endif
        endif
        this._tree.HardRefresh()
        this.SetLines(this._tree.GetPrettyFormatLines())
    enddef # }}}


    def _CallbackAddNode(path: string) # {{{
        var trimmed = path->trim()
        if trimmed == ''
            this._Log('node creation aborted.')
            return
        elseif trimmed->filereadable()
            this._LogErr($'{trimmed} exists already.')
            return
        elseif trimmed[-1] == '/'
            try
                mkdir(trimmed, 'p')
                this._Log($'created directory: {trimmed}.')
            catch /E739/
                this._LogErr($'failed to create directory: {trimmed} (E739).')
            endtry
        else
            try
                []->writefile(trimmed, 'a')
                this._Log($'created file: {trimmed}')
            catch # privileged directory, etc.
                this._LogErr($'failed to create file: {trimmed}.')
            endtry
        endif
        this._tree.HardRefresh()
        this.SetLines(this._tree.GetPrettyFormatLines())
    enddef # }}}


    def _InitHelpText() # {{{
        this._helptext = [
            this._FmtHelp('toggle help', '?'),
            this._FmtHelp('exit poplar', '<esc>'),
            this._FmtHelp('open/expand', '<cr>'),
            this._FmtHelp('open in split', 'i'),
            this._FmtHelp('open in vsplit', 'v'),
            this._FmtHelp('open in tab', 't'),
            this._FmtHelp('raise root by one dir', 'u'),
            this._FmtHelp('set dir as root', 'c'),
            this._FmtHelp('reset cwd as root', 'C'),
            this._FmtHelp('refresh', 'R'),
            this._FmtHelp('show/hide hidden files', 'I'),
            this._FmtHelp('yank full path', 'y'), # <TODO>
            this._FmtHelp('pin/unpin file', 'p'), # <TODO>
            this._FmtHelp('enter modify mode', 'm'),
            this._FmtHelp('---- MODIFY MODE ----'),
            this._FmtHelp('add file/dir', 'a'),
            this._FmtHelp('delete file/dir', 'd'),
            this._FmtHelp('move/rename', 'm'),
            this._FmtHelp('change permissions', 'c'), # <TODO>
            {}
        ]
    enddef # }}}

endclass
