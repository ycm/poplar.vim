vim9script

import './basewindow.vim'
import './filetree.vim'
import './inputline.vim'

export class TreeWindow extends basewindow.BaseWindow
    var _tree: filetree.FileTree
    var _pin_callbacks: dict<func>

    def new(this._on_left,
            this._CallbackSwitchFocus,
            this._CallbackExit,
            this._pin_callbacks)
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
            if this._IsKey(key, g:poplar.keys.TREE_ADD_NODE)
                var starting_text = node.path->isdirectory()
                        ? $'{node.path}/'
                        : $"{node.path->fnamemodify(':h')}/"
                inputline.Open(starting_text,
                               'add a node (dirs end with /)',
                               this._CallbackAddNode,
                               this.ToggleModifyMode)
            elseif this._IsKey(key, g:poplar.keys.TREE_MOVE_NODE)
                if getcwd() =~ $'^{node.path}/'
                    this._LogErr('cannot move dir containing cwd.')
                elseif node.path == getcwd()
                    this._LogErr('cannot move cwd.')
                else
                    inputline.Open(node.path, 'move/rename node',
                                   function(this._CallbackMoveNode, [node.path]),
                                   this.ToggleModifyMode)
                endif
            elseif this._IsKey(key, g:poplar.keys.TREE_DELETE_NODE)
                if getcwd() =~ $'^{node.path}/'
                    this._LogErr('cannot delete dir containing cwd.')
                elseif node.path == getcwd()
                    this._LogErr('cannot delete cwd.')
                else
                    inputline.Open('', $"delete {node.path}? ('yes' to confirm)",
                                   function(this._CallbackDeleteNode, [node.path]),
                                   this.ToggleModifyMode)
                endif
            elseif this._IsKey(key, g:poplar.keys.TREE_CHMOD)
                if getcwd() =~ $'^{node.path}/'
                    this._LogErr('cannot call chmod on dir containing cwd.')
                elseif node.path == getcwd()
                    this._LogErr('cannot call chmod on cwd.')
                else
                    inputline.Open('', $'enter chmod arguments',
                                   function(this._CallbackChmodNode, [node.path]),
                                   this.ToggleModifyMode)
                endif
            endif
        elseif idx >= 0 && this._IsKey(key, g:poplar.keys.TREE_OPEN) # {{{
            var node = this._tree.GetNodeAtDisplayIndex(idx)
            if node.path->isdirectory()
                this._tree.ToggleDir(node)
                this.SetLines(this._tree.GetPrettyFormatLines())
            else
                execute $'drop {node.path->fnamemodify(':~:.')}'
                return this._CallbackExit()
            endif
        elseif idx >= 0 && this._IsKey(key, g:poplar.keys.TREE_OPEN_SPLIT)
            var node = this._tree.GetNodeAtDisplayIndex(idx)
            if !node.path->isdirectory()
                execute $'split {node.path->fnamemodify(':~:.')}'
                return this._CallbackExit()
            endif
        elseif idx >= 0 && this._IsKey(key, g:poplar.keys.TREE_OPEN_VSPLIT)
            var node = this._tree.GetNodeAtDisplayIndex(idx)
            if !node.path->isdirectory()
                execute $'vsplit {node.path->fnamemodify(':~:.')}'
                return this._CallbackExit()
            endif
        elseif idx >= 0 && this._IsKey(key, g:poplar.keys.TREE_OPEN_TAB)
            var node = this._tree.GetNodeAtDisplayIndex(idx)
            if !node.path->isdirectory()
                execute $'tab drop {node.path->fnamemodify(':~:.')}'
                return this._CallbackExit()
            endif
        elseif idx >= 0 && this._IsKey(key, g:poplar.keys.TREE_MODIFY_MODE)
            this.ToggleModifyMode()
        elseif idx >= 0 && this._IsKey(key, g:poplar.keys.TREE_CHROOT)
            var node = this._tree.GetNodeAtDisplayIndex(idx)
            this._tree.ChangeRoot(node)
            this.SetLines(this._tree.GetPrettyFormatLines())
        elseif idx >= 0 && this._IsKey(key, g:poplar.keys.TREE_TOGGLE_PIN)
            var node = this._tree.GetNodeAtDisplayIndex(idx)
            if !(node.path->filereadable())
                this._LogErr($'cannot pin {node.path}')
            else
                this._pin_callbacks.TogglePin(node.path)
            endif
        elseif idx >= 0 && this._IsKey(key, g:poplar.keys.TREE_YANK_PATH)
            var node = this._tree.GetNodeAtDisplayIndex(idx)
            node.path->setreg(g:poplar.yankreg)
            this._Log($"saved '{node.path}' to register '{g:poplar.yankreg}'")
        elseif idx >= 0 && this._IsKey(key, g:poplar.keys.TREE_RUN_CMD)
            var node = this._tree.GetNodeAtDisplayIndex(idx)
            var dir = node.path->isdirectory()
                    ? node.path
                    : node.path->fnamemodify(':h')
            dir = dir->fnamemodify(':~')
            if dir[-1] != '/' # only for /
                dir = dir .. '/'
            endif
            inputline.Open('', $'run system command in {dir}',
                           function(this._CallbackRunSystemCmd, [dir]))
        elseif this._IsKey(key, g:poplar.keys.TREE_TOGGLE_HIDDEN)
            this._tree.ToggleHidden()
            this.SetLines(this._tree.GetPrettyFormatLines())
        elseif this._IsKey(key, g:poplar.keys.TREE_RAISE_ROOT)
            this._tree.RaiseRoot()
            this._tree.HardRefresh()
            this.SetLines(this._tree.GetPrettyFormatLines())
        elseif this._IsKey(key, g:poplar.keys.TREE_CWD_ROOT)
            this._tree.ResetRootToCwd()
            this.SetLines(this._tree.GetPrettyFormatLines())
        elseif this._IsKey(key, g:poplar.keys.TREE_REFRESH)
            this._tree.HardRefresh()
            this.SetLines(this._tree.GetPrettyFormatLines())
        elseif this._IsKey(key, g:poplar.keys.TREE_TOGGLE_HELP)
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


    def _CallbackRunSystemCmd(path: string, cmd: string) # {{{
        if cmd->trim() == ''
            this._Log('operation aborted.')
            return
        endif
        var cwd = getcwd()
        execute $'cd {path}'
        g:poplar.output = cmd->system()->split('\n')
        execute $'cd {cwd}'
        if g:poplar.output->empty()
            this._Log($'ran system command: <{cmd}>.')
        else
            this._Log('see g:poplar.output for output.')
        endif
        this._tree.HardRefresh()
        this.SetLines(this._tree.GetPrettyFormatLines())
    enddef # }}}


    def _CallbackChmodNode(path: string, text: string) # {{{
        var args = text->trim()
        if args == ''
            this._Log('operation aborted.')
            return
        endif
        var cmd = $'chmod {args} {path}'
        var err = cmd->system()->split('\n')
        if err->empty()
            this._Log($'changed permissions to {args} for node: {path}.')
        else
            v:errors->extend(err)
            this._LogErr($"check v:errors -- could not change permissions to {args} for node: {path}.")
        endif
        this._tree.HardRefresh()
        this.SetLines(this._tree.GetPrettyFormatLines())
    enddef # }}}


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
                this._pin_callbacks.Refresh()
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
                this._pin_callbacks.UpdateDir(from, dest)
                this._tree.CheckRenamedDirExpand(from, dest)
                var bufs = getbufinfo()
                        ->filter((_, b) => b.name =~ $'^{from}/')
                        ->mapnew((_, b) => [b.bufnr, b.name[from->len() + 1 :]])
                var wins_replaced = 0
                for [bufnr, basename] in bufs
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
                this._pin_callbacks.UpdatePin(from, dest)
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
        this._pin_callbacks.Refresh()
    enddef # }}}


    def _InitHelpText() # {{{
        this._helptext = [
            this._FmtHelp('toggle help',            g:poplar.keys.TREE_TOGGLE_HELP),
            this._FmtHelp('switch to pin menu',     g:poplar.keys.SWITCH_WINDOW_R),
            this._FmtHelp('exit poplar',            g:poplar.keys.EXIT),
            this._FmtHelp('open/expand',            g:poplar.keys.TREE_OPEN),
            this._FmtHelp('open in split',          g:poplar.keys.TREE_OPEN_SPLIT),
            this._FmtHelp('open in vsplit',         g:poplar.keys.TREE_OPEN_VSPLIT),
            this._FmtHelp('open in tab',            g:poplar.keys.TREE_OPEN_TAB),
            this._FmtHelp('raise root by one dir',  g:poplar.keys.TREE_RAISE_ROOT),
            this._FmtHelp('set dir as root',        g:poplar.keys.TREE_CHROOT),
            this._FmtHelp('reset cwd as root',      g:poplar.keys.TREE_CWD_ROOT),
            this._FmtHelp('run system command',     g:poplar.keys.TREE_RUN_CMD),
            this._FmtHelp('refresh',                g:poplar.keys.TREE_REFRESH),
            this._FmtHelp('show/hide hidden files', g:poplar.keys.TREE_TOGGLE_HIDDEN),
            this._FmtHelp('yank full path',         g:poplar.keys.TREE_YANK_PATH),
            this._FmtHelp('pin/unpin file',         g:poplar.keys.TREE_TOGGLE_PIN),
            this._FmtHelp('enter modify mode',      g:poplar.keys.TREE_MODIFY_MODE),
            this._FmtHelp('---- MODIFY MODE ----'),
            this._FmtHelp('add file/dir',           g:poplar.keys.TREE_ADD_NODE),
            this._FmtHelp('move/rename file/dir',   g:poplar.keys.TREE_MOVE_NODE),
            this._FmtHelp('delete file/dir',        g:poplar.keys.TREE_DELETE_NODE),
            this._FmtHelp('change permissions',     g:poplar.keys.TREE_CHMOD),
            {}
        ]
    enddef # }}}

endclass
