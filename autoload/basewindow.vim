vim9script

import './constants.vim' as CONSTANTS

# BaseWindows should always be doubletons
export class BaseWindow
    var _id = -1
    var _on_left: bool
    var _lines: list<any> = ['nothing to show!']
    var _CallbackSwitchFocus: func(): bool
    var _CallbackExit: func(): bool
    var savestate: dict<any> = null_dict

    def _GetCommonPopupProps(): dict<any> # {{{
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
    enddef # }}}


    def _BaseFilter(id: number, key: string): bool # {{{
        var key_norm = key->keytrans()
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
    enddef # }}}


    def Open(title: string = ' no title ') # {{{
        var opts = this._GetCommonPopupProps()
        opts.title = title
        opts->extend(this.savestate)
        this._id = this._lines->popup_create(opts)

        if this.savestate->has_key('_curpos')
            $':noa call cursor({this.savestate._curpos}, 1)'->win_execute(this._id)
        endif
    enddef # }}}


    def SaveCurrentState() # {{{
        var opts = this._id->popup_getoptions()
        this.savestate = {
            _lines: this._lines,
            _fline: 'w0'->line(this._id),
            _curpos: this._id->getcurpos()[1],
            zindex: opts.zindex,
            cursorline: opts.cursorline
        }
    enddef # }}}


    def GetId(): number # {{{
        return this._id
    enddef # }}}


    def SetLines(new_lines: list<any>) # {{{
        var curr_line = this._id->getcurpos()[1]
        var new_len = new_lines->len()
        this._id->popup_settext(new_lines)
        this._lines = new_lines
        if curr_line > new_len
            var new_lnum = [curr_line, new_len]->min()
            var new_fline = [1, new_len - this._id->popup_getoptions().minheight + 1]->max()
            $':noa call cursor({new_lnum}, 1)'->win_execute(this._id)
            this._id->popup_setoptions({firstline: new_fline})
        endif
    enddef # }}}

endclass
