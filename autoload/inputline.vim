vim9script

import './keycodes.vim'
import './constants.vim' as CONSTANTS

# count composing chars:  strchars()
#                         strcharpart()
# ignore composing chars: strcharlne()
#                         slice()

export def Open(starting_text: string,
                title: string = 'title',
                CallbackEnter: func(string) = null_function)
    if 'poplar_prop_input_text'->prop_type_get() == {}
        'poplar_prop_input_text'->prop_type_add({highlight: 'Normal'})
    endif
    if 'poplar_prop_input_cursor'->prop_type_get() == {}
        'poplar_prop_input_cursor'->prop_type_add({highlight: 'PoplarInv'})
    endif
    g:poplar.input.text = starting_text
    g:poplar.input.CallbackEnter = CallbackEnter
    g:poplar.input = {
        text: starting_text,
        cursor: starting_text->strcharlen(),
        CallbackEnter: CallbackEnter
    }
    g:poplar.input.id = ''->popup_create({
        title: $' {title} ',
        zindex: CONSTANTS.Z_WIN_INPUT,
        highlight: 'Normal',
        minwidth: 50,
        maxwidth: 50,
        minheight: 1,
        maxheight: 1,
        padding: [0, 1, 0, 1],
        border: [],
        borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
        mapping: false,
        filter: ConsumeKey,
    })
    UpdateText()
enddef


def ConsumeKey(id: number, key: string): bool
    var key_norm = key->keytrans()
    # <NOTE> ' '->keytrans() == '<Space>' and '<'->keytrans() == '<lt>'
    var is_printable = key_norm->strcharlen() == 1
            || (key->len() == 1
                && key->char2nr() >= 32
                && key->char2nr() != 127)
    return is_printable ? InsertChar(key) : FilterNonPrintable(key_norm)
enddef


def UpdateText()
    var t = g:poplar.input.text
    var c = g:poplar.input.cursor
    var props = [{col: 1 + t->slice(0, c)->len(), length: 1, type: 'poplar_prop_input_cursor'}]
    if t->len() > 0
        props->add({col: 1, length: t->len(), type: 'poplar_prop_input_text'})
    endif
    g:poplar.input.id->popup_settext([{
        text: c >= t->strcharlen() ? t .. ' ' : t,
        props: props
    }])
enddef


def InsertChar(str: string): bool
    var t = g:poplar.input.text
    var c = g:poplar.input.cursor
    t = t->slice(0, c) .. str .. t->slice(c)
    # handle composing characters
    g:poplar.input.cursor += t->strcharlen() - g:poplar.input.text->strcharlen()
    g:poplar.input.text = t
    UpdateText()
    return true
enddef


def FilterNonPrintable(key: string): bool
    if key ==? '<esc>'
        g:poplar.input.id->popup_close()
        g:poplar.input->filter((_, _) => false) # clear dict
        return true
    elseif key ==? '<cr>'
        g:poplar.input.CallbackEnter(g:poplar.input.text)
        g:poplar.input.id->popup_close()
        g:poplar.input->filter((_, _) => false) # clear dict
        return true
    # ---------------------------- fallthrough -------------------------------
    elseif key ==? '<bs>'
        if g:poplar.input.cursor > 0
            --g:poplar.input.cursor
            var t = g:poplar.input.text
            var c = g:poplar.input.cursor
            g:poplar.input.text = t->slice(0, c) .. t->slice(c + 1)
        endif
    elseif key ==? '<del>'
        var t = g:poplar.input.text
        var c = g:poplar.input.cursor
        if c < t->strcharlen()
            g:poplar.input.text = t->slice(0, c) .. t->slice(c + 1)
        endif
    elseif key ==? '<left>'
        if g:poplar.input.cursor > 0
            --g:poplar.input.cursor
        endif
    elseif key ==? '<right>'
        if g:poplar.input.cursor < g:poplar.input.text->strcharlen()
            ++g:poplar.input.cursor            
        endif
    elseif key ==? '<home>' || key ==? '<c-a>'
        g:poplar.input.cursor = 0
    elseif key ==? '<end>' || key ==? '<c-e>'
        g:poplar.input.cursor = g:poplar.input.text->strcharlen()
    endif
    UpdateText()
    return true
enddef
