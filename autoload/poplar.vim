vim9script

import './treewindow.vim'
import './pinwindow.vim'
import './constants.vim' as CONSTANTS

# TEXT PROPERTIES -------------------------------------------------------- {{{
for [key, val] in CONSTANTS.PROPS ->items()
    var propname = val[0]
    if propname->prop_type_get() != {}
        continue
    endif
    var default  = val[1]
    var fallback = val[2]
    var poplar_hlgroup = $'Poplar{key}'
    if poplar_hlgroup->hlexists()
        propname->prop_type_add({highlight: poplar_hlgroup})
    elseif default->hlexists()
        propname->prop_type_add({highlight: default})
    else
        propname->prop_type_add({highlight: fallback})
    endif
endfor # }}}

export def Run()
    if !g:poplar->has_key('pin_win')
        g:poplar['pin_win'] = pinwindow.PinWindow.new(false, SwitchFocus, Exit)
    endif
    if !g:poplar->has_key('tree_win')
        g:poplar['tree_win'] = treewindow.TreeWindow.new(true, SwitchFocus, Exit, {
            Refresh: g:poplar.pin_win.HardRefresh,
            TogglePin: g:poplar.pin_win.TreeCallbackTogglePin,
            UpdatePin: g:poplar.pin_win.TreeCallbackUpdatePin,
            UpdateDir: g:poplar.pin_win.TreeCallbackUpdateDir
        })
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
        g:poplar.pin_win.SoftRefresh()
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
    g:poplar.pin_win.Write()
    return true
enddef
