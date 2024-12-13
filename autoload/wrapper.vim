vim9script

import './treewindow.vim'
import './pinwindow.vim'

export class PoplarWrapper
    var _tree_win: any
    var _pin_win: any
    
    def new()
        this._tree_win = treewindow.TreeWindow.new()
        this._pin_win = pinwindow.PinWindow.new()
    enddef


    def Run()
        this._tree_win.Open()
        this._pin_win.Open()
        this._tree_win.SetAltWindowId(this._pin_win.GetId())
        this._pin_win.SetAltWindowId(this._tree_win.GetId())

        this._pin_win.RelinquishFocus()
    enddef

endclass
