vim9script

import './basewindow.vim'
import './inputline.vim'

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


    def Write() # {{{
        var paths = this._valid + this._invalid
        if '.poplar.txt'->filereadable()
            try
                paths->writefile('.poplar.txt')
            catch
            endtry
        elseif !paths->empty()
            try
                paths->writefile('.poplar.txt')
                this._Log('created new poplar list: .poplar.txt.')
            catch
                this._LogErr('unable to write to .poplar.txt')
            endtry
        endif
    enddef # }}}


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
                lines->add(this._FormatWithProp(path->fnamemodify(':~:.'), 'prop_poplar_pin_not_found', 1))
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


    def _GetPathIdxFromIdx(idx: number): dict<any> # {{{
        var valid = false
        var true_idx = -1
        if this._valid->empty() && this._invalid->empty()
        elseif idx < 0
            throw $'invalid idx: {idx}'
        elseif this._valid->empty()
            true_idx = idx > 0 ? idx - 1 : idx
        elseif this._invalid->empty() || idx < this._valid->len()
            valid = true
            true_idx = idx
        elseif idx - this._valid->len() - 2 >= 0
            valid = false
            true_idx = idx - this._valid->len() - 2
        endif
        return {valid: valid, idx: true_idx}
    enddef # }}}


    def _SpecificFilter(key: string): bool
        var idx = this._show_help
                ? this._id->getcurpos()[1] - 1 - this._helptext->len()
                : this._id->getcurpos()[1] - 1
        if idx >= 0 && key ==? 'm'
            var info = this._GetPathIdxFromIdx(idx)
            if info.idx >= 0
                var path = info.valid
                        ? this._valid[info.idx]
                        : this._invalid[info.idx]
                inputline.Open(path, 'rename',
                               function(this._CallbackRenamePin, [info.valid, info.idx]))
            endif
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


    def _CallbackRenamePin(valid: bool, idx: number, path: string)
        var p = path->fnamemodify(':p')
        if valid && p->filereadable()
            this._valid[idx] = p 
        elseif valid
            this._valid->remove(idx)
            this._invalid->add(p)
        elseif p->filereadable()
            this._invalid->remove(idx)
            this._valid->add(p)
        else
            this._invalid[idx] = p
        endif
        this.InitLines()
    enddef


    def _InitHelpText() # {{{
        this._helptext = [
            this._FmtHelp('toggle help', '?'),
            this._FmtHelp('exit poplar', '<esc>'),
            this._FmtHelp('modify item', 'm'),
            {}
        ]
    enddef # }}}

endclass
