vim9script

import './basewindow.vim'

export class PinWindow extends basewindow.BaseWindow

    def new(this._on_left,
            this._CallbackSwitchFocus,
            this._CallbackExit)
    enddef


    def Open()
        this._lines = 'the quick brown fox'->split(' ')
        var opts = this._GetCommonPopupProps()
        opts.title = ' pinned '
        opts->extend(this.savestate)
        this._id = popup_create(this._lines, opts)

        if this.savestate->has_key('_curpos')
            $':noa call cursor({this.savestate._curpos}, 1)'->win_execute(this._id)
        endif
    enddef


    def _SpecificFilter(key: string): bool
        if key == 'h'
            this._CallbackSwitchFocus()
        endif
        return true
    enddef

endclass
