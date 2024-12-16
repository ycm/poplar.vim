vim9script

import './treewindow.vim'
import './pinwindow.vim'
import './constants.vim' as CONSTANTS


export def Run()
    if !g:poplar->has_key('tree_win')
        g:poplar['tree_win'] = treewindow.TreeWindow.new(true, SwitchFocus, Exit)
    endif
    if !g:poplar->has_key('pin_win')
        g:poplar['pin_win'] = pinwindow.PinWindow.new(false, SwitchFocus, Exit)
    endif

    g:poplar.tree_win.Open(' poplar ')
    g:poplar.pin_win.Open(' pinned ')

    if g:poplar.tree_win.savestate->empty()
        g:poplar.tree_win.GetId()->popup_setoptions({
            zindex: CONSTANTS.Z_WIN_FOCUS,
            cursorline: true
        })
        g:poplar.pin_win.GetId()->popup_setoptions({
            zindex: CONSTANTS.Z_WIN_NOFOCUS,
            cursorline: false
        })
        g:poplar.tree_win.InitLines()
        g:poplar.pin_win.InitLines()
    endif
enddef


def SwitchFocus(): bool
    var opts1 = g:poplar.tree_win.GetId()->popup_getoptions()
    var opts2 = g:poplar.pin_win.GetId()->popup_getoptions()
    g:poplar.tree_win.GetId()->popup_setoptions({
        zindex: opts2.zindex,
        cursorline: !opts1.cursorline
    })
    g:poplar.pin_win.GetId()->popup_setoptions({
        zindex: opts1.zindex,
        cursorline: !opts2.cursorline
    })
    return true
enddef


def Exit(): bool
    g:poplar.tree_win.SaveCurrentState()
    g:poplar.tree_win.GetId()->popup_close()
    g:poplar.pin_win.SaveCurrentState()
    g:poplar.pin_win.GetId()->popup_close()
    return true
enddef
