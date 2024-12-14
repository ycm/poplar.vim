vim9script

import './basewindow.vim'

export class TreeWindow extends basewindow.BaseWindow

    def new(this._on_left,
            this._CallbackSwitchFocus,
            this._CallbackExit)
    enddef


    def Open()
        this._lines = 'lorem ipsum dolor sit amet'->split(' ')
        var opts = this._GetCommonPopupProps()
        opts.title = ' poplar '
        opts->extend(this.savestate)
        this._id = popup_create(this._lines, opts)

        if this.savestate->has_key('_curpos')
            $':noa call cursor({this.savestate._curpos}, 1)'->win_execute(this._id)
        endif
    enddef


    def _SpecificFilter(key: string): bool
        if key == 'l'
            this._CallbackSwitchFocus()
        endif
        return true
    enddef

endclass
