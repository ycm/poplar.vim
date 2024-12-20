vim9script

import './basewindow.vim'

export class PinWindow extends basewindow.BaseWindow
    var _valid: list<string> = []
    var _invalid: list<string> = []

    def new(this._on_left,
            this._CallbackSwitchFocus,
            this._CallbackExit)
        this._InitHelpText()
        this._LoadPaths()
    enddef


    def _LoadPaths() # {{{
        if !'.poplar.txt'->filereadable()
            return
        endif
        var paths = '.poplar.txt'->readfile()
        this._valid = []
        this._invalid = []
        for path in paths
            path->filereadable()
                    ? this._valid->add(path)
                    : this._invalid->add(path)
        endfor
    enddef # }}}


    def InitLines()
        this.SetLines(this._FormatLines())
    enddef


    def _FormatLines(): list<dict<any>> # {{{
        var lines: list<dict<any>> = []
        if this._valid->empty() && this._invalid->empty()
            return lines
        endif
        for path in this._valid
            lines->add(this._FormatWithProp(path->fnamemodify(':~:.'), null_string, 1))
        endfor
        if !this._valid->empty() && !this._invalid->empty()
            lines->add({})
        endif
        if !this._invalid->empty()
            lines->add(this._FormatWithProp('Not found:', 'prop_poplar_pin_not_found'))
            for path in this._invalid
                lines->add(this._FormatWithProp(path, 'prop_poplar_pin_not_found', 1))
            endfor
        endif
        return lines
    enddef # }}}


    def _FormatWithProp(text: string, # {{{
                        prop: string = null_string,
                        indent: number = 0): dict<any>
        return prop == null
                ? {text: '  '->repeat(indent) .. text}
                : {text: '  '->repeat(indent) .. text,
                  props: [{col: 1 + 2 * indent, length: text->len(), type: prop}]}
    enddef # }}}


    def _GetPathAtIndex(idx: number): string # {{{
        if this._valid->empty() && this._invalid->empty()
            return null_string
        elseif idx < 0
            throw $'invalid idx: {idx}'
        elseif this._valid->empty()
            return idx > 0 ? this._invalid[idx - 1] : null_string
        elseif this._invalid->empty()
            return this._valid[idx]
        elseif idx < this._valid->len()
            return this._valid[idx]
        elseif idx - this._valid->len() - 2 >= 0
            return this._invalid[idx - this._valid->len() - 2]
        endif
        return null_string
    enddef # }}}


    def _SpecificFilter(key: string): bool
        var idx = this._show_help
                ? this._id->getcurpos()[1] - 1 - this._helptext->len()
                : this._id->getcurpos()[1] - 1
        if idx >= 0 && key ==? '<cr>'
            var path = this._GetPathAtIndex(idx)
            echomsg path
        elseif key == '?'
            this._show_help = !this._show_help
            this.SetLines(this._lines, false)
            if this._show_help
                ':noa call cursor(1, 1)'->win_execute(this._id)
            else
                var lnum = [
                    1, this._id->getcurpos()[1] - this._helptext->len()
                ]->max()
                $':noa call cursor({lnum}, 1)'->win_execute(this._id)
            endif
        endif
        return true
    enddef


    def _InitHelpText() # {{{
        this._helptext = [
            this._FmtHelp('toggle help', '?'),
            this._FmtHelp('exit poplar', '<esc>'),
            this._FmtHelp('blablabla', 'b'),
            {}
        ]
    enddef # }}}

endclass
