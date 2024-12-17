vim9script

export const Z_WIN_INPUT   = 150
export const Z_WIN_FOCUS   = 100
export const Z_WIN_NOFOCUS = 50
export const MAX_HEIGHT    = 20
export const MIN_WIDTH     = 50

export const K_IGNORE = [
    '<cursorhold>',
]

export const PROPS = {
    # name: [prop, default, fallback]
    TreeDir:      ['prop_poplar_tree_dir',       'NERDTreeDir',      'Directory'],
    TreeFile:     ['prop_poplar_tree_file',      'NERDTreeFile',     'Normal'],
    TreeExecFile: ['prop_poplar_tree_exec_file', 'NERDTreeExecFile', 'Keyword'],
    InputText:    ['prop_poplar_input_text',     'Normal',           'Normal'],
    InputCursor:  ['prop_poplar_input_cursor',   'PoplarInv',        'PoplarInv'],
}
