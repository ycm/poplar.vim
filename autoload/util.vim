vim9script



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


export def MaybeParseGitStatus(): dict<string>
    if !g:poplar.showgit || $"{'git rev-parse --is-inside-work-tree'->system()->trim()}" != 'true'
        return {}
    endif
    var statuses = 'git status --porcelain'->system()->split('\n')
    var statdict = {}
    for line in statuses
        var status = ParseGitStatusFlags(line[: 1])
        var path = line[2 :]->trim()->fnamemodify(':p')
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
        var gicon = g:poplar.git_icons[git_status]
        var gprop = g:poplar.git_status_props[git_status]
        str = prefix .. gicon .. ' ' .. text
        props->add({col: ind + prefix->len(), length: gicon->len(), type: gprop})
        props->add({col: ind + prefix->len() + gicon->len() + 1, length: str->len(), type: prop})
    else
        props->add({col: ind + prefix->len(), length: str->len(), type: prop})
    endif
    return {text: '  '->repeat(indents) .. str, props: props}
enddef
