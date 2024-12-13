vim9script

var KEYS_1BYTE = {
    1: '<c-a>',
    5: '<c-e>',
    9: '<tab>',
    13: '<cr>',
    27: '<esc>',
}

var KEYS_3BYTE = {
    'ku': '<up>',
    'kd': '<down>',
    'kl': '<left>',
    'kr': '<right>',
    'kb': '<bs>',
    'kD': '<del>',
    'kh': '<home>',
    '@7': '<end>',
    'kB': '<s-tab>',
    'PS': '<paste-start>',
    'PE': '<paste-end>',
}

export def NormalizeKey(key: string): string
    if key->len() == 1
        return get(KEYS_1BYTE, char2nr(key), key)
    endif
    return get(KEYS_3BYTE, key[1 :], key)
enddef
