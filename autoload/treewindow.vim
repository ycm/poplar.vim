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
    enddef


    def InitLines()
        if !this.savestate->empty()
            throw $'fatal: tried InitLines() on existing tree'
        endif
        this.SetLines(this._tree.GetPrettyFormatLines())
    enddef


    def _SpecificFilter(key: string): bool
        if key ==? '<cr>'
            var idx = this._id->getcurpos()[1] - 1
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
            inputline.Open('ABCDEFGH', 'title', this._CallbackInputLineEnter)
        elseif key == 'C' # placeholder key
            this._tree.RaiseRoot()
            this.SetLines(this._tree.GetPrettyFormatLines())
        elseif key == 'c' # placeholder key
            var idx = this._id->getcurpos()[1] - 1
            var node = this._tree.GetNodeAtDisplayIndex(idx)
            this._tree.ChangeRoot(node)
            this.SetLines(this._tree.GetPrettyFormatLines())
        endif
        return true
    enddef


    def _CallbackInputLineEnter(text: string)
        echom $'placeholder: received <{text}>'
    enddef

endclass
