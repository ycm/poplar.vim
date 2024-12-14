vim9script

import './basewindow.vim'
import './filetree.vim'

export class TreeWindow extends basewindow.BaseWindow
    var _tree: any

    def new(this._on_left,
            this._CallbackSwitchFocus,
            this._CallbackExit)
        this._tree = filetree.FileTree.new(getcwd())
        this._tree.ToggleDir(this._tree.root)
    enddef


    def InitLines()
        assert_true(this.savestate->empty())
        var lines = this._tree.GetTextList()
        this.SetLines(lines)
    enddef


    def _SpecificFilter(key: string): bool
        return true
    enddef

endclass
