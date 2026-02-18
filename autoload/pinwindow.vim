vim9script

import './basewindow.vim'
import './inputline.vim'
import './util.vim' as util


export class PinWindow extends basewindow.BaseWindow
    var _valid: list<string> = []
    var _invalid: list<string> = []

    def new(this._on_left,
            this._CallbackSwitchFocus,
            this._CallbackExit)
        this._helptext = util.GetPinWindowHelp()
    enddef


    def SoftRefresh()
        this.SetLines(this._FormatLines())
    enddef


    def HardRefresh()
        this._RefreshPaths()
        this.SoftRefresh()
    enddef


    def LoadPaths() # {{{
        if !g:poplar.filename->filereadable()
            return
        endif
        var paths = g:poplar.filename->readfile()
        this._valid = []
        this._invalid = []
        for path in paths
            if path->filereadable() && this._valid->index(path) < 0
                this._valid->add(path->fnamemodify(':p'))
            elseif !path->filereadable() && this._invalid->index(path) < 0
                this._invalid->add(path->fnamemodify(':p'))
            endif
        endfor
    enddef # }}}


    def TreeCallbackUpdateDir(from: string, to: string)
        var oldpath = from->fnamemodify(':p')
        var newpath = to->fnamemodify(':p')
        if oldpath[-1] != '/'
            oldpath = oldpath .. '/'
        endif
        if newpath[-1] != '/'
            newpath = newpath .. '/'
        endif
        for i in this._valid->len()->range()
            if this._valid[i] =~ $'^{oldpath}'
                this._valid[i] = newpath .. this._valid[i][oldpath->strcharlen() :]
            endif
        endfor
        this.HardRefresh()
    enddef


    def TreeCallbackTogglePin(path: string)
        if !path->filereadable()
            return
        endif
        var p = path->fnamemodify(':p')
        var shortp = p->fnamemodify(':~:.')
        var idx = this._valid->index(p)
        if idx >= 0
            util.Log($"unpinned: {shortp}.")
            this._valid->remove(idx)
        else
            this._valid->add(p)
            util.Log($'pinned: {shortp}.')
        endif
        this.HardRefresh()
    enddef


    def TreeCallbackUpdatePin(from: string, to: string) # {{{
        var idx = this._valid->index(from->fnamemodify(':p'))
        if idx >= 0
            this._valid[idx] = to->fnamemodify(':p')
        endif
        this.HardRefresh()
    enddef # }}}


    def Write() # {{{
        var paths = this._valid + this._invalid
        if g:poplar.filename->filereadable()
            try
                paths->writefile(g:poplar.filename, 's')
            catch
                util.LogErr($'unable to write to {g:poplar.filename}')
            endtry
        elseif !paths->empty()
            try
                paths->writefile(g:poplar.filename, 's')
                util.Log($'created new poplar list: {g:poplar.filename}.')
            catch
                util.LogErr($'unable to write to {g:poplar.filename}')
            endtry
        endif
    enddef # }}}


    def _FormatLines(): list<dict<any>> # {{{
        if this._valid->empty() && this._invalid->empty()
            return [this._FormatWithProp('no pins yet!', 'prop_poplar_help_text', 1)]
        endif
        var lines: list<dict<any>> = []
        for path in this._valid
            var prop = path->executable() ? 'prop_poplar_tree_exec_file' : 'prop_poplar_tree_file'
            lines->add(this._FormatWithProp(path->fnamemodify(':~:.'), prop, 1))
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


    def _SpecificFilter(key: string): bool # {{{
        var idx = this._show_help
                ? this._id->getcurpos()[1] - 1 - this._helptext->len()
                : this._id->getcurpos()[1] - 1
        # ----------------------- only in modify mode ------------------------
        if this._show_modify_mode
            if this._IsKey(key, g:poplar.keys.PIN_ADD)
                var text = getcwd()[-1] == '/' ? getcwd() : getcwd() .. '/'
                inputline.Open(text, 'add a pin', this._CallbackPin, this.ToggleModifyMode)
            elseif idx >= 0 && this._IsKey(key, g:poplar.keys.PIN_MODIFY)
                var info = this._GetPathIdxFromIdx(idx)
                if info.idx >= 0
                    var path = info.valid ? this._valid[info.idx] : this._invalid[info.idx]
                    inputline.Open(path, 'modify pin',
                                   function(this._CallbackRenamePin, [info.valid, info.idx]),
                                   this.ToggleModifyMode)
                endif
            elseif idx >= 0 && this._IsKey(key, g:poplar.keys.PIN_DELETE)
                var info = this._GetPathIdxFromIdx(idx)
                if info.idx >= 0
                    var path = info.valid ? this._valid[info.idx] : this._invalid[info.idx]
                    inputline.Open('', $"unpin {path->fnamemodify(':~:.')}? ('yes' to confirm)",
                                   function(this._CallbackUnpin, [info.valid, info.idx]),
                                   this.ToggleModifyMode)
                endif
            endif
        # -------------------- cursorline can be anywhere --------------------
        elseif this._IsKey(key, g:poplar.keys.PIN_MODIFY_MODE)
            this.ToggleModifyMode()
        elseif this._IsKey(key, g:poplar.keys.PIN_REFRESH)
            this.HardRefresh()
        elseif this._IsKey(key, g:poplar.keys.PIN_TOGGLE_HELP)
            this._show_help = !this._show_help
            this.SetLines(this._lines, false)
            if this._show_help
                ':noa call cursor(1, 1)'->win_execute(this._id)
            else
                var lnum = [1, this._id->getcurpos()[1] - this._helptext->len()]->max()
                $':noa call cursor({lnum}, 1)'->win_execute(this._id)
            endif
        # ---------------- cursorline must be on a valid file ----------------
        elseif idx >= 0
            if (this._IsKey(key, g:poplar.keys.PIN_OPEN) && this._TryOpenFile(idx, 'drop'))
            || (this._IsKey(key, g:poplar.keys.PIN_OPEN_SPLIT) && this._TryOpenFile(idx, 'split'))
            || (this._IsKey(key, g:poplar.keys.PIN_OPEN_VSPLIT) && this._TryOpenFile(idx, 'vsplit'))
            || (this._IsKey(key, g:poplar.keys.PIN_OPEN_TAB) && this._TryOpenFile(idx, 'tab drop'))
            || (this._IsKey(key, g:poplar.keys.PIN_OPEN_SYS) && this._TryOpenFile(idx, 'Open'))
                return this._CallbackExit()
            elseif this._IsKey(key, g:poplar.keys.PIN_YANK_PATH)
                var info = this._GetPathIdxFromIdx(idx)
                if info.idx >= 0
                    var path = info.valid
                            ? this._valid[info.idx]
                            : this._invalid[info.idx]
                    path->setreg(g:poplar.yankreg)
                    util.Log($"saved '{path}' to register '{g:poplar.yankreg}'")
                endif
            elseif this._IsKey(key, g:poplar.keys.PIN_MOVE_DOWN)
                var info = this._GetPathIdxFromIdx(idx)
                if info.valid && info.idx >= 0 && info.idx + 1 < this._valid->len()
                    [this._valid[info.idx], this._valid[info.idx + 1]] = [
                        this._valid[info.idx + 1], this._valid[info.idx]]
                    'j'->feedkeys()
                elseif !info.valid && info.idx >= 0 && info.idx + 1 < this._invalid->len()
                    [this._invalid[info.idx], this._invalid[info.idx + 1]] = [
                        this._invalid[info.idx + 1], this._invalid[info.idx]]
                    'j'->feedkeys()
                endif
                this.SoftRefresh()
            elseif this._IsKey(key, g:poplar.keys.PIN_MOVE_UP)
                var info = this._GetPathIdxFromIdx(idx)
                if info.valid && info.idx > 0 && this._valid->len() > 1
                    [this._valid[info.idx], this._valid[info.idx - 1]] = [
                        this._valid[info.idx - 1], this._valid[info.idx]]
                    'k'->feedkeys()
                elseif !info.valid && info.idx > 0 && this._invalid->len() > 1
                    [this._invalid[info.idx], this._invalid[info.idx - 1]] = [
                        this._invalid[info.idx - 1], this._invalid[info.idx]]
                    'k'->feedkeys()
                endif
                this.SoftRefresh()
            endif
        endif
        return true
    enddef # }}}


    def _TryOpenFile(idx: number, cmd: string): bool
        var info = this._GetPathIdxFromIdx(idx)
        if info.idx >= 0
            var path = info.valid
                    ? this._valid[info.idx]
                    : this._invalid[info.idx]
            execute $"{cmd} {path->fnamemodify(':~:.')}"
            return true
        endif
        return false
    enddef


    def _RefreshPaths() # {{{
        for path in this._invalid
            if path->filereadable() && this._valid->index(path) < 0
                this._valid->add(path)
            endif
        endfor
        for path in this._valid
            if !path->filereadable() && this._invalid->index(path) < 0
                this._invalid->add(path)
            endif
        endfor
        this._valid->filter((_, p) => p->filereadable())
        this._invalid->filter((_, p) => !p->filereadable())
    enddef # }}}


    def _CallbackPin(path: string) # {{{
        var p = path->trim()->simplify()
        if p == ''
            util.Log($'operation aborted.')
            return
        endif
        p = p->fnamemodify(':p')
        if p->filereadable()
            if this._valid->index(p) >= 0
                util.Log($'already pinned: {p}.')
            else
                this._valid->add(p)
                util.Log($'pinned a file: {p}.')
            endif
        else
            if this._invalid->index(p) >= 0
                util.LogErr($'invalid file: {p}.')
            else
                this._invalid->add(p)
                util.Log($'pinned an invalid file: {p}.')
            endif
        endif
        this.SoftRefresh()
    enddef # }}}


    def _CallbackRenamePin(valid: bool, idx: number, path: string) # {{{
        var p = path->trim()->simplify()
        if p == ''
            util.Log('rename aborted.')
            return
        endif
        p = p->fnamemodify(':p')
        if valid && p->filereadable()
            this._valid->remove(idx)
            if this._valid->index(p) >= 0
                util.Log($'already pinned: {p}.')
            else
                this._valid->insert(p, idx)
                util.Log($'pinned a file: {p}.')
            endif
        elseif valid
            this._valid->remove(idx)
            if this._invalid->index(p) < 0
                this._invalid->add(p)
                util.Log($'pinned an invalid file: {p}.')
            endif
        elseif p->filereadable()
            this._invalid->remove(idx)
            if this._valid->index(p) >= 0
                util.Log($'already pinned: {p}.')
            else
                this._valid->add(p)
                util.Log($'pinned a file: {p}.')
            endif
        else
            this._invalid->remove(idx)
            if this._invalid->index(p) < 0
                this._invalid->insert(p, idx)
                util.Log($'pinned an invalid file: {p}.')
            endif
        endif
        this.SoftRefresh()
    enddef # }}}


    def _CallbackUnpin(valid: bool, idx: number, confirm: string) # {{{
        if confirm->trim() !=? 'yes'
            util.Log("didn't unpin anything.")
            return
        endif
        if valid
            util.Log($'unpinned: {this._valid[idx]}')
            this._valid->remove(idx)
        else
            util.Log($'unpinned: {this._invalid[idx]}')
            this._invalid->remove(idx)
        endif
        this.SoftRefresh()
    enddef # }}}


endclass
