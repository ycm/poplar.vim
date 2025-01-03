vim9script


export class BaseWindow
    var _id = -1
    var _on_left: bool
    var _show_modify_mode = false
    var _lines: list<dict<any>> = []
    var _CallbackSwitchFocus: func(): bool
    var _CallbackExit: func(): bool
    var _helptext: list<dict<any>>
    var _show_help = false
    var savestate: dict<any> = null_dict
    var title: string

    def _GetCommonPopupProps(): dict<any> # {{{
        var maxheight = [&lines - 8, 0]->max()
        var trueheight = [20, maxheight]->min()
        var props = {
            pos: 'topleft',
            col: &columns / 2 + 2,
            # line: (&lines - maxheight) / 2 - 1, # <TODO> reflect true height here
            firstline: this.savestate->get('firstline', 1),
            minwidth: g:poplar.dims.MIN_WIDTH,
            maxwidth: (&columns / 2) - 8,
            minheight: trueheight,
            maxheight: trueheight,
            filter: this._BaseFilter,
            border: [],
            borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
            padding: [0, 1, 0, 1],
            highlight: 'Pmenu',
            mapping: false
        }

        if this._on_left
            --props.col
            props.pos = 'topright'
        endif

        return props
    enddef # }}}


    def _BaseFilter(id: number, key: string): bool # {{{
        var key_norm = key->keytrans()
        if this._IsKey(key_norm, g:poplar.keys.EXIT)
            if this._show_modify_mode
                this.ToggleModifyMode()
                return true
            else
                return this._CallbackExit()
            endif
        elseif !this._show_modify_mode && (key_norm == 'j' || key_norm ==? '<down>')
            var disp_len = this._show_help
                    ? this._helptext->len() + this._lines->len()
                    : this._lines->len()
            if this._id->getcurpos()[1] >= disp_len
                return true
            endif
            return this._id->popup_filter_menu(key)
        elseif !this._show_modify_mode && (key_norm == 'k' || key_norm ==? '<up>')
            if this._id->getcurpos()[1] <= 1
                return true
            endif
            return this._id->popup_filter_menu(key)
        elseif !this._show_modify_mode && this._IsKey(key_norm, g:poplar.keys.GO_TO_TOP)
            'normal! gg'->win_execute(this._id)
            return true
        elseif !this._show_modify_mode && this._IsKey(key_norm, g:poplar.keys.GO_TO_BOTTOM)
            'normal! G'->win_execute(this._id)
            return true
        elseif (!this._show_modify_mode && this._IsKey(key_norm, g:poplar.keys.SWITCH_WINDOW_L) && !this._on_left)
            || (!this._show_modify_mode && this._IsKey(key_norm, g:poplar.keys.SWITCH_WINDOW_R) && this._on_left)
            return this._CallbackSwitchFocus()
        endif
        return this._SpecificFilter(key_norm)
    enddef # }}}


    def ToggleModifyMode() # {{{
        if this._show_modify_mode
            this._show_modify_mode = false
            this._id->popup_setoptions({
                title: $' {this.title} ',
                highlight: 'Pmenu',
            })
        else
            this._show_modify_mode = true
            this._id->popup_setoptions({
                title: $' {this.title} {g:poplar.modify_text} ',
                highlight: 'Keyword',
            })
        endif
    enddef # }}}


    def Open(title: string = 'no title') # {{{
        var opts = this._GetCommonPopupProps()
        this.title = title
        opts.title = $' {title} '
        opts->extend(this.savestate)
        var lines = this._show_help
                ? this._helptext + this._lines
                : this._lines
        this._id = lines->popup_create(opts)

        if this.savestate->has_key('_curpos')
            $':noa call cursor({this.savestate._curpos}, 1)'
                    ->win_execute(this._id)
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


    def SetLines(new_lines: list<dict<any>>, move_cursor: bool = true) # {{{
        var curr_line = this._id->getcurpos()[1]
        var new_len = new_lines->len()
        if this._show_help
            this._id->popup_settext(this._helptext + new_lines)
            new_len += this._helptext->len()
        else
            this._id->popup_settext(new_lines)
        endif
        this._lines = new_lines
        if curr_line > new_len
            var new_lnum = [curr_line, new_len]->min()
            var new_fline = [
                1, new_len - this._id->popup_getoptions().minheight + 1
            ]->max()
            if move_cursor
                $':noa call cursor({new_lnum}, 1)'->win_execute(this._id)
            endif
            this._id->popup_setoptions({firstline: new_fline})
        endif
    enddef # }}}


    def _IsKey(key1: string, key2: string): bool # {{{
        return key2->strcharlen() == 1
                ? key1 == key2
                : key1 ==? key2
    enddef # }}}

endclass
