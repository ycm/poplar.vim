vim9script

import './basewindow.vim'

export class TreeWindow extends basewindow.BaseWindow

    def new(this._on_left,
            this._CallbackSwitchFocus,
            this._CallbackExit)
    enddef


    def InitLines()
        assert_true(this.savestate->empty())
        var lines = 'placeholder text'->split()
        this.SetLines(lines)
    enddef


    def _SpecificFilter(key: string): bool
        return true
    enddef

endclass
