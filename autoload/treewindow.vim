vim9script

import './basewindow.vim'
import './filetree.vim' as FT
import './inputline.vim'
import './util.vim' as util

export class TreeWindow extends basewindow.BaseWindow
    var _tree: FT.FileTree
    var _pin_callbacks: dict<func>

    def new(this._on_left,
            this._CallbackSwitchFocus,
            this._CallbackExit,
            this._pin_callbacks)
        this._tree = FT.FileTree.new(getcwd())
        this._tree.ToggleDir(this._tree.root)
        this._helptext = util.GetTreeWindowHelp()
    enddef


    def InitLines()
        this.SetLines(this._tree.GetPrettyFormatLines())
    enddef


    def _SpecificFilter(key: string): bool
        var idx = this._show_help
                ? this._id->getcurpos()[1] - 1 - this._helptext->len()
                : this._id->getcurpos()[1] - 1
        # ----------------------- only in modify mode ------------------------
        if idx >= 0 && this._show_modify_mode
            var node = this._tree.GetNodeAtDisplayIndex(idx)
            if this._IsKey(key, g:poplar.keys.TREE_ADD_NODE)
                var starting_text = node.path->isdirectory()
                        ? $'{node.path}/'
                        : $"{node.path->fnamemodify(':h')}/"
                inputline.Open(starting_text, 'add a node (dirs end with /)',
                               this._CallbackAddNode, this.ToggleModifyMode)
            elseif this._IsKey(key, g:poplar.keys.TREE_MOVE_NODE)
                this._ModifyNode(node, 'move/rename node', node.path,
                                 function(this._CallbackMoveNode, [node.path]))
            elseif this._IsKey(key, g:poplar.keys.TREE_DELETE_NODE)
                this._ModifyNode(node, $"delete {node.path}? ('yes' to confirm)", '',
                                 function(this._CallbackDeleteNode, [node.path]))
            elseif this._IsKey(key, g:poplar.keys.TREE_CHMOD)
                this._ModifyNode(node, 'enter chmod arguments', '',
                                 function(this._CallbackChmodNode, [node.path]))
            endif
        # -------------------- cursorline can be anywhere --------------------
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
                var lnum = [1, this._id->getcurpos()[1] - this._helptext->len()]->max()
                $':noa call cursor({lnum}, 1)'->win_execute(this._id)
            endif
        # -------------- cursorline must be on a valid file/dir --------------
        elseif idx >= 0
            var node = this._tree.GetNodeAtDisplayIndex(idx)
            if this._IsKey(key, g:poplar.keys.TREE_MODIFY_MODE)
                this.ToggleModifyMode()
            elseif this._IsKey(key, g:poplar.keys.TREE_OPEN)
                if node.path->isdirectory()
                    this._tree.ToggleDir(node)
                    this.SetLines(this._tree.GetPrettyFormatLines())
                else
                    execute $'drop {node.path->fnamemodify(':~:.')}'
                    return this._CallbackExit()
                endif
            elseif this._IsKey(key, g:poplar.keys.TREE_OPEN_SPLIT) && !node.path->isdirectory()
                execute $'split {node.path->fnamemodify(':~:.')}'
                return this._CallbackExit()
            elseif this._IsKey(key, g:poplar.keys.TREE_OPEN_VSPLIT) && !node.path->isdirectory()
                execute $'vsplit {node.path->fnamemodify(':~:.')}'
                return this._CallbackExit()
            elseif this._IsKey(key, g:poplar.keys.TREE_OPEN_TAB) && !node.path->isdirectory()
                execute $'tab drop {node.path->fnamemodify(':~:.')}'
                return this._CallbackExit()
            elseif this._IsKey(key, g:poplar.keys.TREE_CHROOT)
                this._tree.ChangeRoot(node)
                this.SetLines(this._tree.GetPrettyFormatLines())
            elseif this._IsKey(key, g:poplar.keys.TREE_TOGGLE_PIN)
                if node.path->isdirectory()
                    util.LogErr($'cannot pin {node.path}: is a directory.')
                elseif !(node.path->filereadable())
                    util.LogErr($'cannot pin {node.path}: not a readable file.')
                else
                    this._pin_callbacks.TogglePin(node.path)
                endif
            elseif this._IsKey(key, g:poplar.keys.TREE_YANK_PATH)
                node.path->setreg(g:poplar.yankreg)
                util.Log($"saved '{node.path}' to register '{g:poplar.yankreg}'.")
            elseif this._IsKey(key, g:poplar.keys.TREE_RUN_CMD)
                var dir = node.path->isdirectory() ? node.path : node.path->fnamemodify(':h')
                dir = dir->fnamemodify(':~')
                dir = dir[-1] == '/' ? dir : $'{dir}/'
                inputline.Open('', $'run system command in {dir}',
                               function(this._CallbackRunSystemCmd, [dir]))
            endif
        endif
        return true
    enddef


    def _ModifyNode(node: FT.FileTreeNode, prompt_title: string,
                    starting_input: string, CallbackEnter: func(string))
        if getcwd() =~ $'^{node.path}/' || node.path == getcwd()
            util.LogErr('operation not permitted.')
        else
            inputline.Open(starting_input, prompt_title, CallbackEnter, this.ToggleModifyMode)
        endif
    enddef


    def _CallbackRunSystemCmd(path: string, cmd: string) # {{{
        if cmd->trim() == ''
            util.Log('operation aborted.')
            return
        endif
        var cwd = getcwd()
        execute $'cd {path}'
        g:poplar.output = cmd->system()->split('\n')
        execute $'cd {cwd}'
        if g:poplar.output->empty()
            util.Log($'ran system command: <{cmd}>.')
        else
            util.Log('see g:poplar.output for output.')
        endif
        this._tree.HardRefresh()
        this.SetLines(this._tree.GetPrettyFormatLines())
    enddef # }}}


    def _CallbackChmodNode(path: string, text: string) # {{{
        var args = text->trim()
        if args == ''
            util.Log('operation aborted.')
            return
        endif
        var cmd = $'chmod {args} {path}'
        var err = cmd->system()->split('\n')
        if err->empty()
            util.Log($'changed permissions to {args} for node: {path}.')
        else
            v:errors->extend(err)
            util.LogErr($"check v:errors -- could not change permissions to {args} for node: {path}.")
        endif
        this._tree.HardRefresh()
        this.SetLines(this._tree.GetPrettyFormatLines())
    enddef # }}}


    def _CallbackDeleteNode(path: string, confirm: string) # {{{
        if confirm->trim() !=? 'yes'
            util.Log($'node deletion aborted.')
            return
        endif
        if path->isdirectory()
            if path->delete('d') == 0
                util.Log($'deleted directory {path}.')
            else
                util.LogErr($'could not delete directory {path}.')
            endif
        else
            if path->delete() == 0
                var winids = path->bufnr()->win_findbuf()
                for winid in winids
                    $':noa | q!'->win_execute(winid)
                endfor
                if winids == []
                    util.Log($'deleted file {path}.')
                else
                    util.Log($'deleted file {path} and removed {winids->len()} windows.')
                endif
                this._pin_callbacks.Refresh()
            else
                util.LogErr($'could not delete file: {path}.')
            endif
        endif
        this._tree.HardRefresh()
        this.SetLines(this._tree.GetPrettyFormatLines())
    enddef # }}}


    def _CallbackMoveNode(from: string, to: string) # {{{
        var dest = to->trim()->simplify()
        if dest == ''
            util.Log('operation aborted.')
            return
        elseif from->isdirectory()
            if dest[-1] != '/'
                dest = dest .. '/'
            endif
            if rename(from, dest) == -1
                util.LogErr($'failed to move directory {from}.')
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
                    util.Log($'renamed directory to {dest}.')
                else
                    util.Log($'renamed directory to {dest} and switched buffers in {wins_replaced} windows.')
                endif
            endif
        elseif dest->filereadable()
            util.LogErr($'file already exists: {dest}.')
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
                util.LogErr($'failed to move file from {from} to {dest}.')
            else
                this._pin_callbacks.UpdatePin(from, dest)
                var winids = from->bufnr()->win_findbuf()
                dest = dest->fnamemodify(':~:.')
                for winid in winids
                    $':noa | edit! {dest}'->win_execute(winid)
                endfor
                if winids == []
                    util.Log($'moved file to {dest}.')
                else
                    util.Log($'moved file to {dest} and switched buffer(s) in {winids->len()} windows.')
                endif
            endif
        endif
        this._tree.HardRefresh()
        this.SetLines(this._tree.GetPrettyFormatLines())
    enddef # }}}


    def _CallbackAddNode(path: string) # {{{
        var trimmed = path->trim()->simplify()
        if trimmed == ''
            util.Log('node creation aborted.')
            return
        elseif trimmed->filereadable()
            util.LogErr($'{trimmed} exists already.')
            return
        elseif trimmed[-1] == '/'
            try
                mkdir(trimmed, 'p')
                util.Log($'created directory: {trimmed}.')
            catch /E739/
                util.LogErr($'failed to create directory: {trimmed} (E739).')
            endtry
        else
            try
                []->writefile(trimmed, 'a')
                util.Log($'created file: {trimmed}')
            catch # privileged directory, etc.
                util.LogErr($'failed to create file: {trimmed}.')
            endtry
        endif
        this._tree.HardRefresh()
        this.SetLines(this._tree.GetPrettyFormatLines())
        this._pin_callbacks.Refresh()
    enddef # }}}

endclass
