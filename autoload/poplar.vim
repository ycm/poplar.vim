vim9script

import './treewindow.vim'
import './pinwindow.vim'

if !'g:poplar'->exists()
    g:poplar = {}
endif
g:poplar.input = {}
g:poplar.dims = {
    Z_WIN_INPUT:   150,
    Z_WIN_FOCUS:   100,
    Z_WIN_NOFOCUS: 50,
    MAX_HEIGHT:    20,
    MIN_WIDTH:     40
}
var default_keys = { # {{{
    SWITCH_WINDOW_L:    'h',
    SWITCH_WINDOW_R:    'l',
    EXIT:               '<esc>',
    PIN_TOGGLE_HELP:    '?',
    PIN_OPEN:           '<cr>',
    PIN_OPEN_SPLIT:     'i',
    PIN_OPEN_VSPLIT:    'v',
    PIN_OPEN_TAB:       't',
    PIN_MODIFY_MODE:    'm',
    PIN_ADD:            'a',
    PIN_MODIFY:         'm',
    PIN_DELETE:         'd',
    PIN_REFRESH:        'R',
    PIN_MOVE_DOWN:      'J',
    PIN_MOVE_UP:        'K',
    PIN_YANK_PATH:      'y',
    TREE_TOGGLE_HELP:   '?',
    TREE_OPEN:          '<cr>',
    TREE_OPEN_SPLIT:    'i',
    TREE_OPEN_VSPLIT:   'v',
    TREE_OPEN_TAB:      't',
    TREE_RAISE_ROOT:    'u',
    TREE_CHROOT:        'c',
    TREE_CWD_ROOT:      'C',
    TREE_REFRESH:       'R',
    TREE_TOGGLE_HIDDEN: 'I',
    TREE_YANK_PATH:     'y',
    TREE_TOGGLE_PIN:    'p',
    TREE_MODIFY_MODE:   'm',
    TREE_ADD_NODE:      'a',
    TREE_MOVE_NODE:     'm',
    TREE_DELETE_NODE:   'd',
    TREE_CHMOD:         'P'
} # }}}
if 'g:poplar.keys'->exists()
    default_keys->extend(g:poplar.keys)
    g:poplar.keys = default_keys
else
    g:poplar.keys = default_keys
endif

g:poplar.yankreg = g:poplar->get('yankreg', '+')
g:poplar.verbosity = g:poplar->get('verbosity', 'all')
g:poplar.diropensymb = g:poplar->get('diropensymb', 'v')
g:poplar.dirclosedsymb = g:poplar->get('dirclosedsymb', '>')
g:poplar.filename = g:poplar->get('filename', '.poplar.txt')

g:poplar.k_ignore = ['<cursorhold>']
g:poplar.textprops = {
    TreeDir:      ['prop_poplar_tree_dir',       'NERDTreeDir',      'Directory'],
    TreeCWD:      ['prop_poplar_tree_cwd',       'Keyword',          'Keyword'],
    TreeFile:     ['prop_poplar_tree_file',      'NERDTreeFile',     'Identifier'],
    TreeExecFile: ['prop_poplar_tree_exec_file', 'NERDTreeExecFile', 'Keyword'],
    InputText:    ['prop_poplar_input_text',     'Normal',           'Normal'],
    InputCursor:  ['prop_poplar_input_cursor',   'PoplarInv',        'PoplarInv'],
    HelpText:     ['prop_poplar_help_text',      'Comment',          'Comment'],
    HelpKey:      ['prop_poplar_help_key',       'Keyword',          'Keyword'],
    PinNotFound:  ['prop_poplar_pin_not_found',  'ErrorMsg',         'ErrorMsg']
}
g:poplar.modify_text = '(modify-mode)'

# TEXT PROPERTIES -------------------------------------------------------- {{{
for [key, val] in g:poplar.textprops->items()
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
    g:poplar.user_pmenu = 'Pmenu'->hlget()
    g:poplar.user_pmenusel = 'PmenuSel'->hlget()
    if 'PoplarMenuSel'->hlexists()
        highlight! link PmenuSel PoplarMenuSel
    endif
    if 'PoplarMenu'->hlexists()
        highlight! link Pmenu PoplarMenu
    endif

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
            zindex: g:poplar.dims.Z_WIN_FOCUS,
            cursorline: true
        })
        g:poplar.pin_win.GetId()->popup_setoptions({
            zindex: g:poplar.dims.Z_WIN_NOFOCUS,
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
    g:poplar.user_pmenu->hlset()
    g:poplar.user_pmenusel->hlset()
    return true
enddef
