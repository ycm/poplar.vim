vim9script

# count composing chars:  strchars()
#                         strcharpart()
# ignore composing chars: strcharlne()
#                         slice()

export def Open(starting_text: string,
                title: string = 'title',
                CallbackEnter: func(string) = null_function,
                CallbackExit: func(): void = null_function)
    var tinfo = g:poplar.tree_win.GetId()->popup_getpos()
    var pinfo = g:poplar.pin_win.GetId()->popup_getpos()
    var width = tinfo.width + pinfo.width
            + tinfo.scrollbar + pinfo.scrollbar - 4
    var line = tinfo.line + [tinfo.height, pinfo.height]->max() - 1
    g:poplar.input = {
        text: starting_text,
        cursor: starting_text->strcharlen(),
        CallbackEnter: CallbackEnter,
        CallbackExit: CallbackExit,
        width: width,
        xoffset: 0,
        ispaste: false,
        pastestr: '',
    }
    g:poplar.input.id = ''->popup_create({
        title: $' {title} ',
        zindex: g:poplar.dims.Z_WIN_INPUT,
        highlight: 'Normal',
        minwidth: g:poplar.input.width,
        maxwidth: g:poplar.input.width,
        minheight: 1,
        maxheight: 1,
        col: tinfo.col,
        line: line,
        padding: [0, 1, 0, 1],
        border: [],
        borderchars: ['─', '│', '─', '│', '├', '┤', '╯', '╰'],
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
    return is_printable ? Insert(key) : FilterNonPrintable(key_norm)
enddef


def UpdateText()
    var txt = g:poplar.input.text
    var cur = g:poplar.input.cursor
    var xos = g:poplar.input.xoffset
    var width = g:poplar.input.width

    # <INFO> If cursor is at the end of the string, display as much text as
    # possible by setting the viewport's left edge to the lowest value for
    # which the cursor is displayed.
    if cur == txt->strcharlen()
        xos = cur->range()
                ->filter((_, i) => $'{txt} '[i : cur]->strwidth() <= width)
                ->min()
    # <INFO> OTOH if cursor is mid-text but to the right of the viewport,
    # increment the viewport's left edge until cursor is displayed
    elseif cur > xos
            && cur > xos->range(1 + txt->strcharlen())
                    ->filter((_, i) => txt[xos : i]->strwidth() <= width)
                    ->max()
        while xos <= cur && txt[xos : cur]->strwidth() > width
            ++xos
        endwhile
    # <INFO> Otherwise, decrement the viewport's left edge until cursor is
    # displayed on the left half of the viewport.
    elseif cur <= xos
            || (cur > xos && txt[xos : cur]->strwidth() < width / 2)
        xos = [cur, xos]->min()
        while xos > 0 && txt[xos : cur]->strwidth() < width / 2
            --xos
        endwhile
    endif

    var tspc = cur == txt->strcharlen() ? $'{txt} ' : txt
    g:poplar.input.xoffset = xos
    g:poplar.input.id->popup_settext([{
        text: tspc[xos :],
        props: [
            {col: 1, length: tspc[xos :]->len(),
             type: 'prop_poplar_input_text'},
            {col: 1 + tspc->slice(xos, cur)->len(), length: 1,
             type: 'prop_poplar_input_cursor'}
        ]
    }])
enddef


def Insert(str: string): bool
    if g:poplar.input.ispaste
        g:poplar.input.pastestr = g:poplar.input.pastestr .. str
        return true
    endif

    var txt = g:poplar.input.text
    var cur = g:poplar.input.cursor
    txt = txt->slice(0, cur) .. str .. txt->slice(cur)
    # handle composing characters
    g:poplar.input.cursor += txt->strcharlen()
            - g:poplar.input.text->strcharlen()
    g:poplar.input.text = txt
    UpdateText()
    return true
enddef


def FilterNonPrintable(key: string): bool
    if key ==? '<esc>'
        g:poplar.input.id->popup_close()
        if g:poplar.input.CallbackExit != null
            g:poplar.input.CallbackExit()
        endif
        g:poplar.input->filter((_, _) => false) # clear dict
        return true
    elseif key ==? '<pastestart>'
        g:poplar.input.ispaste = true
        return true
    elseif key ==? '<pasteend>'
        g:poplar.input.ispaste = false
        Insert(g:poplar.input.pastestr)
        g:poplar.input.pastestr = ''
        return true
    elseif g:poplar.input.ispaste
        return true
    elseif key ==? '<cr>'
        g:poplar.input.CallbackEnter(g:poplar.input.text)
        g:poplar.input.id->popup_close()
        if g:poplar.input.CallbackExit != null
            g:poplar.input.CallbackExit()
        endif
        g:poplar.input->filter((_, _) => false) # clear dict
        return true
    elseif g:poplar.k_ignore->index(key) >= 0
        return true
    # ---------------------------- fallthrough -------------------------------
    elseif key ==? '<bs>'
        if g:poplar.input.cursor > 0
            --g:poplar.input.cursor
            var txt = g:poplar.input.text
            var cur = g:poplar.input.cursor
            g:poplar.input.text = txt->slice(0, cur) .. txt->slice(cur + 1)
        endif
    elseif key ==? '<del>'
        var txt = g:poplar.input.text
        var cur = g:poplar.input.cursor
        if cur < txt->strcharlen()
            g:poplar.input.text = txt->slice(0, cur) .. txt->slice(cur + 1)
        endif
    elseif key ==? '<left>'
        if g:poplar.input.cursor > 0
            --g:poplar.input.cursor
        endif
    elseif key ==? '<right>'
        if g:poplar.input.cursor < g:poplar.input.text->strcharlen()
            ++g:poplar.input.cursor            
        endif
    elseif key ==? '<c-left>'
        if g:poplar.input.cursor > 0
            --g:poplar.input.cursor
            while g:poplar.input.cursor > 0 && g:poplar.input.text[g:poplar.input.cursor] != '/'
                --g:poplar.input.cursor
            endwhile
        endif
    elseif key ==? '<c-right>'
        var txt = g:poplar.input.text
        if g:poplar.input.cursor < txt->strcharlen()
            ++g:poplar.input.cursor
            while g:poplar.input.cursor < txt->strcharlen() && txt[g:poplar.input.cursor] != '/'
                ++g:poplar.input.cursor
            endwhile
        endif
    elseif key ==? '<home>' || key ==? '<c-a>'
        g:poplar.input.cursor = 0
    elseif key ==? '<end>' || key ==? '<c-e>'
        g:poplar.input.cursor = g:poplar.input.text->strcharlen()
    endif
    UpdateText()
    return true
enddef
