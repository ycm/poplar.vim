vim9script

import './keycodes.vim'
import './constants.vim' as CONSTANTS

# BaseWindows should always be doubletons
export class BaseWindow
    var _id = -1
    var _alt_id = -1
    var _lines: list<any>

    def _GetCommonPopupProps(): dict<any>
        var true_height = [&lines - 6, CONSTANTS.MAX_HEIGHT]->min()
        return {
            col: &columns / 2,
            line: (&lines - true_height) / 2 - 1,
            cursorline: true,
            minwidth: CONSTANTS.MIN_WIDTH,
            minheight: true_height,
            maxheight: true_height,
            filter: this._BaseFilter,
            border: [],
            borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
            padding: [0, 1, 0, 1],
            highlight: 'Constant',
            zindex: CONSTANTS.Z_WIN_FOCUS,
        }
    enddef


    def _BaseFilter(id: number, key: string): bool
        var key_norm = keycodes.NormalizeKey(key)

        if key_norm ==? '<esc>'
            this._alt_id->popup_close()
            return this._id->popup_filter_menu(key)
        elseif key_norm ==? 'j'
            return this._id->popup_filter_menu(key)
        elseif key_norm ==? 'k'
            return this._id->popup_filter_menu(key)
        endif

        return this._SpecificFilter(key_norm)
    enddef


    def RelinquishFocus()
        assert_true(this._id > 0 && this._alt_id > 0,
            $'invalid winids for call to RelinquishFocus: {this._id}, {this._alt_id}')
        this._id->popup_setoptions({
            cursorline: false,
            zindex: CONSTANTS.Z_WIN_NOFOCUS
        })
        this._alt_id->popup_setoptions({
            cursorline: true,
            zindex: CONSTANTS.Z_WIN_FOCUS
        })
    enddef


    def _SpecificFilter(key: string): bool
        throw '_SpecificFilter was not specified!'
        return this._id->popup_filter_menu(key)
    enddef


    def GetId(): number
        return this._id
    enddef


    def SetAltWindowId(alt_id: number)
        this._alt_id = alt_id
    enddef


    def new()
    enddef

endclass
