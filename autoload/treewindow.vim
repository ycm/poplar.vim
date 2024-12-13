vim9script

import './basewindow.vim'
import './constants.vim' as CONSTANTS

export class TreeWindow extends basewindow.BaseWindow

    def Open()
        this._lines = 'lorem ipsum dolor sit amet'->split(' ')
        var opts = this._GetCommonPopupProps()
        opts->extend({
            title: ' poplar ',
            pos: 'topright',
        })
        this._id = popup_create(this._lines, opts)
    enddef


    def _SpecificFilter(key: string): bool
        if key == 'l'
            this.RelinquishFocus()
        endif
        return true
    enddef

endclass
