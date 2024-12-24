vim9script

export def Log(msg: string)
    if g:poplar.verbosity == 'all'
        echomsg $'[poplar] {msg}'
    endif
enddef


export def LogErr(err: string)
    if g:poplar.verbosity != 'silent'
        echohl ErrorMsg
        Log(err)
        echohl None
    endif
enddef


def FormatHelp(annot: string, key: string = ''): dict<any>
    if key == ''
        return {
            text: annot,
            props: [{col: 1, length: annot->len(),
                    type: 'prop_poplar_help_text'}]
        }
    endif
    return {
        text: $'{key}: {annot}',
        props: [
            {col: 1, length: key->len(), type: 'prop_poplar_help_key'},
            {col: 1 + key->len(), length: 2 + annot->len(),
            type: 'prop_poplar_help_text'}
        ]
    }
enddef

export def GetTreeWindowHelp(): list<dict<any>>
    return [
        FormatHelp('toggle help',            g:poplar.keys.TREE_TOGGLE_HELP),
        FormatHelp('switch to pin menu',     g:poplar.keys.SWITCH_WINDOW_R),
        FormatHelp('exit poplar',            g:poplar.keys.EXIT),
        FormatHelp('open/expand',            g:poplar.keys.TREE_OPEN),
        FormatHelp('open in split',          g:poplar.keys.TREE_OPEN_SPLIT),
        FormatHelp('open in vsplit',         g:poplar.keys.TREE_OPEN_VSPLIT),
        FormatHelp('open in tab',            g:poplar.keys.TREE_OPEN_TAB),
        FormatHelp('raise root by one dir',  g:poplar.keys.TREE_RAISE_ROOT),
        FormatHelp('set dir as root',        g:poplar.keys.TREE_CHROOT),
        FormatHelp('reset cwd as root',      g:poplar.keys.TREE_CWD_ROOT),
        FormatHelp('run system command',     g:poplar.keys.TREE_RUN_CMD),
        FormatHelp('refresh',                g:poplar.keys.TREE_REFRESH),
        FormatHelp('show/hide hidden files', g:poplar.keys.TREE_TOGGLE_HIDDEN),
        FormatHelp('yank full path',         g:poplar.keys.TREE_YANK_PATH),
        FormatHelp('pin/unpin file',         g:poplar.keys.TREE_TOGGLE_PIN),
        FormatHelp('enter modify mode',      g:poplar.keys.TREE_MODIFY_MODE),
        FormatHelp('---- MODIFY MODE ----'),
        FormatHelp('add file/dir',           g:poplar.keys.TREE_ADD_NODE),
        FormatHelp('move/rename file/dir',   g:poplar.keys.TREE_MOVE_NODE),
        FormatHelp('delete file/dir',        g:poplar.keys.TREE_DELETE_NODE),
        FormatHelp('change permissions',     g:poplar.keys.TREE_CHMOD),
        {}
    ]
enddef


export def GetPinWindowHelp(): list<dict<any>>
    return [
        FormatHelp('toggle help',         g:poplar.keys.PIN_TOGGLE_HELP),
        FormatHelp('switch to tree menu', g:poplar.keys.SWITCH_WINDOW_L),
        FormatHelp('exit poplar',         g:poplar.keys.EXIT),
        FormatHelp('open',                g:poplar.keys.PIN_OPEN),
        FormatHelp('open in split',       g:poplar.keys.PIN_OPEN_SPLIT),
        FormatHelp('open in vsplit',      g:poplar.keys.PIN_OPEN_VSPLIT),
        FormatHelp('open in tab',         g:poplar.keys.PIN_OPEN_TAB),
        FormatHelp('refresh',             g:poplar.keys.PIN_REFRESH),
        FormatHelp('move item down',      g:poplar.keys.PIN_MOVE_DOWN),
        FormatHelp('move item up',        g:poplar.keys.PIN_MOVE_UP),
        FormatHelp('yank full path',      g:poplar.keys.PIN_YANK_PATH),
        FormatHelp('enter modify mode',   g:poplar.keys.PIN_MODIFY_MODE),
        FormatHelp('---- MODIFY MODE ----'),
        FormatHelp('add pin',             g:poplar.keys.PIN_ADD),
        FormatHelp('modify pin',          g:poplar.keys.PIN_MODIFY),
        FormatHelp('delete pin',          g:poplar.keys.PIN_DELETE),
        {}
    ]
enddef


export def ParseGitStatusFlags(xy: string): string
    # cf. https://github.com/Xuyuanp/nerdtree-git-plugin
    if xy->len() != 2
        return 'unknown'
    endif
    var [X, Y] = [xy[0], xy[1]]
    if xy == '??'
        return 'untracked'
    elseif xy == '!!'
        return 'ignored'
    elseif Y == 'M'
        return 'modified'
    elseif X =~ '[RC]' || Y =~ '[RC]'
        return 'renamed'
    elseif X =~ '[MA]'
        return 'staged'
    endif
    return 'unknown'
enddef


def IsInsideGitTree(): bool
    return $"{'git rev-parse --is-inside-work-tree'->system()->trim()}" == 'true'
enddef


export def GetGitBranchName(): string
    if IsInsideGitTree()
        var branch = 'git rev-parse --abbrev-ref HEAD'->system()->trim()
        return branch == '' || branch->split('\n')->len() != 1 ? null_string : branch
    endif
    return null_string
enddef


export def MaybeParseGitStatus(): dict<string>
    if !g:poplar.showgit || !IsInsideGitTree()
        return {}
    endif
    var statuses = 'git status --porcelain'->system()->split('\n')
    var statdict = {}
    for line in statuses
        var status = ParseGitStatusFlags(line[: 1])
        var path = status == 'renamed'
                ? line[2 :]->split(' -> ')[-1]->trim()->fnamemodify(':p')
                : line[2 :]->trim()->fnamemodify(':p')
        if path->isdirectory()
            path = path->fnamemodify(':h')
        endif
        if !statdict->has_key(path) 
            statdict[path] = status
        elseif statdict[path] != status
            statdict[path] = 'multiple'
        endif
        if path =~ '^' .. getcwd()
            while path->fnamemodify(':h') != getcwd() && path != '/' && path != ''
                path = path->fnamemodify(':h')
            endwhile
        endif
        if !statdict->has_key(path) 
            statdict[path] = status
        elseif statdict[path] != status
            statdict[path] = 'multiple'
        endif
    endfor
    return statdict
enddef


export def FormatWithProp(text: string,
                          prop: string,
                          indents: number = 0,
                          git_status: string = '',
                          prefix: string = ''): dict<any>
    var str = prefix .. text
    var ind = 2 * indents + 1
    var props = [{col: ind, length: prefix->len(), type: prop}]
    if git_status != ''
        var gicon = g:poplar.giticons[git_status]
        var gprop = g:poplar.git_status_props[git_status]
        str = prefix .. gicon .. ' ' .. text
        props->add({col: ind + prefix->len(), length: gicon->len(), type: gprop})
        props->add({col: ind + prefix->len() + gicon->len() + 1, length: str->len(), type: prop})
    else
        props->add({col: ind + prefix->len(), length: str->len(), type: prop})
    endif
    return {text: '  '->repeat(indents) .. str, props: props}
enddef
