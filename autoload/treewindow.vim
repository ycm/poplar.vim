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
                               this._CallbackInputLineAddNode,
                               this.ToggleModifyMode)
            elseif key == 'm'
                inputline.Open(node.path,
                               'move/rename node',
                               function(this._CallbackInputLineRenameNode, [node.path]),
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
            var node = this._tree.GetNodeAtDisplayIndex(idx)
            if node.path->isdirectory() && node.path == getcwd()
                this._LogErr('cannot modify cwd.')
            else
                this.ToggleModifyMode()
            endif
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
                var lnum = [1, this._id->getcurpos()[1] - this._helptext->len()]->max()
                $':noa call cursor({lnum}, 1)'->win_execute(this._id)
            endif # ------------------------------------------------------ }}}
        endif
        return true
    enddef


    def _CallbackInputLineEnter(text: string)
        this._Log($'placeholder received <{text}>')
    enddef


    def _CallbackInputLineRenameNode(from: string, to: string)
        var dest = to->trim()
        if from->isdirectory()
            # <TODO>
        elseif dest->filereadable()
            this._LogErr($'file already exists: {dest}.')
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
            if rename(from, $'{dest}') == -1
                this._LogErr($'failed to move file to {dest}.')
            else
                this._Log($'moved file to {dest}.')
            endif
        endif
        this._tree.HardRefresh()
        this.SetLines(this._tree.GetPrettyFormatLines())
    enddef


    def _CallbackInputLineAddNode(path: string) # {{{
        var trimmed = path->trim()
        if trimmed[-1] == '/'
            try
                mkdir(trimmed, 'p')
                this._Log($'created directory: {trimmed}.')
            catch /E739/
                this._LogErr($'failed to create directory: {trimmed} (E739).')
            endtry
        elseif trimmed->filereadable()
            this._LogErr($'{trimmed} exists already.')
            return
        else
            try
                []->writefile(trimmed, 'a')
                this._Log($'created file: {trimmed}')
            catch # privileged directory, etc.
                this._LogErr($'failed to create file: {trimmed}.')
        echom $'placeholder: received <{text}>'
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
            this._FmtHelp('set cwd as root', 'C'),
            this._FmtHelp('refresh', 'R'),
            this._FmtHelp('show/hide hidden files', 'I'),
            this._FmtHelp('enter modify mode', 'm'),
            this._FmtHelp('---- MODIFY MODE ----'),
            this._FmtHelp('add file/dir', 'a'),
            this._FmtHelp('delete file/dir', 'd'),
            this._FmtHelp('move/rename', 'm'),
            {}
        ]
    enddef # }}}

endclass
