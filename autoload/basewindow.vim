vim9script

import './constants.vim' as CONSTANTS

# BaseWindows should always be doubletons
export class BaseWindow
    var _id = -1
    var _on_left: bool
    var _show_modify_mode = false
    var _lines: list<any> = ['nothing to show!']
    var _CallbackSwitchFocus: func(): bool
    var _CallbackExit: func(): bool
    var savestate: dict<any> = null_dict

    def _GetCommonPopupProps(): dict<any> # {{{
        var maxheight = [&lines - 8, 0]->max()
        var props = {
            pos: 'topleft',
            col: &columns / 2 + 2,
            # line: (&lines - maxheight) / 2 - 1, # <TODO> reflect true height here
            firstline: this.savestate->get('firstline', 1),
            minwidth: CONSTANTS.MIN_WIDTH,
            maxwidth: (&columns / 2) - 8,
            minheight: maxheight / 2, # <TODO> fix this logic
            maxheight: maxheight,
            filter: this._BaseFilter,
            border: [],
            borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
            padding: [0, 1, 0, 1],
            highlight: 'Normal',
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
            if this._show_modify_mode
                this.ToggleModifyMode()
                return true
            else
                return this._CallbackExit()
            endif
        elseif !this._show_modify_mode && key_norm == 'j'
            if this._id->getcurpos()[1] >= this._lines->len()
                return true
            endif
            return this._id->popup_filter_menu(key)
        elseif !this._show_modify_mode && key_norm == 'k'
            if this._id->getcurpos()[1] <= 1
                return true
            endif
            return this._id->popup_filter_menu(key)
        elseif (!this._show_modify_mode && key_norm == 'h' && !this._on_left)
            || (!this._show_modify_mode && key_norm == 'l' && this._on_left)
            return this._CallbackSwitchFocus()
        endif
        return this._SpecificFilter(key_norm)
    enddef # }}}


    def ToggleModifyMode()
        var title = this._id->popup_getoptions().title
        if this._show_modify_mode
            this._show_modify_mode = false
            this._id->popup_setoptions({
                title: title[: -(CONSTANTS.MODIFY_TEXT->len()) - 2],
                highlight: 'Normal',
            })
        else
            this._show_modify_mode = true
            this._id->popup_setoptions({
                title: $'{title}{CONSTANTS.MODIFY_TEXT} ',
                highlight: 'Keyword',
            })
        endif
    enddef


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
            _curpos: this._id->getcurpos()[1],
            firstline: 'w0'->line(this._id),
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
