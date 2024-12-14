vim9script

import './treewindow.vim'
import './pinwindow.vim'
import './constants.vim' as CONSTANTS

export class PoplarWrapper
    var _tree_win: any
    var _pin_win: any

    def new()
        this._tree_win = treewindow.TreeWindow.new(
            true, this.SwitchFocus, this.Exit)
        this._pin_win = pinwindow.PinWindow.new(
            false, this.SwitchFocus, this.Exit)
    enddef


    def Run()
        this._tree_win.Open()
        this._pin_win.Open()

        if !this._tree_win.savestate->has_key('zindex')
            this._tree_win.GetId()->popup_setoptions({
                zindex: CONSTANTS.Z_WIN_FOCUS,
                cursorline: true
            })
            this._pin_win.GetId()->popup_setoptions({
                zindex: CONSTANTS.Z_WIN_NOFOCUS,
                cursorline: false
            })
        endif
    enddef


    def SwitchFocus(): bool
        var opts1 = this._tree_win.GetId()->popup_getoptions()
        var opts2 = this._pin_win.GetId()->popup_getoptions()
        this._tree_win.GetId()->popup_setoptions({
            zindex: opts2.zindex,
            cursorline: !opts1.cursorline
        })
        this._pin_win.GetId()->popup_setoptions({
            zindex: opts1.zindex,
            cursorline: !opts2.cursorline
        })
        return true
    enddef


    def Exit(): bool
        this._tree_win.SaveCurrentState()
        this._tree_win.GetId()->popup_close()
        this._pin_win.SaveCurrentState()
        this._pin_win.GetId()->popup_close()
        return true
    enddef

endclass
