vim9script

import './keycodes.vim'
import './constants.vim' as CONSTANTS

# BaseWindows should always be doubletons
export class BaseWindow
    var _id = -1
    var _lines: list<any>
    var _on_left: bool
    var _CallbackSwitchFocus: func(): bool
    var _CallbackExit: func(): bool
    var savestate: dict<any> = null_dict

    def _GetCommonPopupProps(): dict<any>
        var true_height = [&lines - 6, CONSTANTS.MAX_HEIGHT]->min()
        var props = {
            pos: 'topleft',
            col: &columns / 2 + 1,
            line: (&lines - true_height) / 2 - 1,
            firstline: this.savestate->get('firstline', 1),
            minwidth: CONSTANTS.MIN_WIDTH,
            minheight: true_height,
            maxheight: true_height,
            filter: this._BaseFilter,
            border: [],
            borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
            padding: [0, 1, 0, 1],
            highlight: 'Constant',
        }
        if this._on_left
            --props.col
            props.pos = 'topright'
        endif

        return props
    enddef


    def _BaseFilter(id: number, key: string): bool
        var key_norm = keycodes.NormalizeKey(key)

        if key_norm ==? '<esc>'
            return this._CallbackExit()
        elseif key_norm == 'j'
            if this._id->getcurpos()[1] >= this._lines->len()
                return true
            endif
            return this._id->popup_filter_menu(key)
        elseif key_norm == 'k'
            if this._id->getcurpos()[1] <= 1
                return true
            endif
            return this._id->popup_filter_menu(key)
        elseif (key_norm == 'h' && !this._on_left)
            || (key_norm == 'l' && this._on_left)
            return this._CallbackSwitchFocus()
        endif

        return this._SpecificFilter(key_norm)
    enddef

    
    def SaveCurrentState()
        var opts = this._id->popup_getoptions()
        this.savestate = {
            _fline: 'w0'->line(this._id),
            _curpos: this._id->getcurpos()[1],
            zindex: opts.zindex,
            cursorline: opts.cursorline
        }
    enddef


    def _SpecificFilter(key: string): bool
        throw '_SpecificFilter was not specified!'
        return false
    enddef


    def GetId(): number
        return this._id
    enddef

endclass
