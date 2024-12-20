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

export const MODIFY_TEXT = '(modify-mode)'
