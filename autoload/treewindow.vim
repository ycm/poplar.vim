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
        if !this.savestate->empty()
            throw $'fatal: tried InitLines() on existing tree'
        endif
        this.SetLines(this._tree.GetPrettyFormatLines())
    enddef


    def _SpecificFilter(key: string): bool
        if this._show_modify_mode
            if key == 'm' # <TODO>
                inputline.Open('ABCDEFGH', 'rename',
                               this._CallbackInputLineEnter,
                               this.ToggleModifyMode)
                return true
            endif
            return true
        endif
        if key ==? '<cr>'
            var idx = this._id->getcurpos()[1] - 1
            if this._show_help
                idx -= this._helptext->len()
            endif
            if idx < 0
                return true
            endif
            var node = this._tree.GetNodeAtDisplayIndex(idx)
            if node.path->isdirectory()
                this._tree.ToggleDir(node)
                this.SetLines(this._tree.GetPrettyFormatLines())
            else
                execute $'drop {node.path->fnamemodify(':~:.')}'
                return this._CallbackExit()
            endif
        elseif key == 'I'
            this._tree.ToggleHidden()
            this.SetLines(this._tree.GetPrettyFormatLines())
        elseif key == 'm'
            this.ToggleModifyMode()
        elseif key == 'u'
            this._tree.RaiseRoot()
            this.SetLines(this._tree.GetPrettyFormatLines())
        elseif key == 'c'
            var idx = this._id->getcurpos()[1] - 1
            var node = this._tree.GetNodeAtDisplayIndex(idx)
            this._tree.ChangeRoot(node)
            this.SetLines(this._tree.GetPrettyFormatLines())
        elseif key == 'C'
            this._tree.ResetRootToCwd()
            this.SetLines(this._tree.GetPrettyFormatLines())
        elseif key == 'R'
            this._tree.HardRefresh()
            this.SetLines(this._tree.GetPrettyFormatLines())
        elseif ['i', 't', 'v']->index(key) >= 0
            var idx = this._id->getcurpos()[1] - 1
            if this._show_help
                idx += this._helptext->len()
            endif
            if idx < 0
                return true
            endif
            var node = this._tree.GetNodeAtDisplayIndex(idx)
            if !node.path->isdirectory()
                var cmd = {'i': 'split', 'v': 'vsplit', 't': 'tab drop'}
                execute $'{cmd[key]} {node.path->fnamemodify(':~:.')}'
                return this._CallbackExit()
            endif
        elseif key == '?'
            this._show_help = !this._show_help
            this.SetLines(this._lines)
        endif
        return true
    enddef


    def _CallbackInputLineEnter(text: string)
        echom $'placeholder: received <{text}>'
    enddef


    def _InitHelpText()
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
            this._FmtHelp('-- MODIFY MODE --'),
            this._FmtHelp('enter modify mode', 'm'),
            {}
        ]
    enddef

endclass
