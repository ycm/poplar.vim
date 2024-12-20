vim9script

export const Z_WIN_INPUT   = 150
export const Z_WIN_FOCUS   = 100
export const Z_WIN_NOFOCUS = 50
export const MAX_HEIGHT    = 20
export const MIN_WIDTH     = 40

export const K_IGNORE = [
    '<cursorhold>',
]

export const PROPS = {
    TreeDir:      ['prop_poplar_tree_dir',       'NERDTreeDir',      'Directory'],
    TreeCWD:      ['prop_poplar_tree_cwd',       'Keyword',          'Keyword'],
    TreeFile:     ['prop_poplar_tree_file',      'NERDTreeFile',     'Identifier'],
    TreeExecFile: ['prop_poplar_tree_exec_file', 'NERDTreeExecFile', 'Keyword'],
    InputText:    ['prop_poplar_input_text',     'Normal',           'Normal'],
    InputCursor:  ['prop_poplar_input_cursor',   'PoplarInv',        'PoplarInv'],
    HelpText:     ['prop_poplar_help_text',      'Comment',          'Comment'],
    HelpKey:      ['prop_poplar_help_key',       'Keyword',          'Keyword'],
    PinNotFound:  ['prop_poplar_pin_not_found',  'ErrorMsg',         'ErrorMsg'],
}

export const KEYS = { # {{{
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
    TREE_DELETE_NODE:   'd',
    TREE_MOVE_NODE:     'm',
    TREE_CHMOD:         'x'
} # }}}

export const MODIFY_TEXT = '(modify-mode)'
