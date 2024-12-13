vim9script

import './basewindow.vim'
import './constants.vim' as CONSTANTS

export class PinWindow extends basewindow.BaseWindow

    def Open()
        this._lines = 'the quick brown fox'->split(' ')
        var opts = this._GetCommonPopupProps()
        opts->extend({
            col: opts.col + 1,
            title: ' pinned ',
            pos: 'topleft',
        })
        this._id = popup_create(this._lines, opts)
    enddef


    def _SpecificFilter(key: string): bool
        if key == 'h'
            this.RelinquishFocus()
        endif
        return true
    enddef

endclass
