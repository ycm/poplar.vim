vim9script

export class FileTreeNode # {{{
    var path: string
    public var children: list<FileTreeNode> = null_list

    def new(this.path)
    enddef

endclass # }}}


export class FileTree
    var root: FileTreeNode # not necessarily cwd
    var _text_list: list<dict<any>>
    var _show_hidden: bool
    var _expanded_paths: dict<string> # this is a set

    def new(root_path: string)
        this.root = FileTreeNode.new(root_path)
    enddef


    def HardRefresh()
        this.root = FileTreeNode.new(this.root.path)
        def Recur(node: FileTreeNode)
            this._EnsureExpand(node)
            for child in node.children
                if this._expanded_paths->has_key(child.path)
                    Recur(child)
                endif
            endfor
        enddef
        Recur(this.root)
    enddef


    def ChangeRoot(node: FileTreeNode)
        if !node.path->isdirectory() || node == this.root
            return
        endif
        this.root = node
        this.HardRefresh()
    enddef


    def ResetRootToCwd()
        this.root = FileTreeNode.new(getcwd())
        this.HardRefresh()
    enddef


    def CheckRenamedDirExpand(from: string, to: string)
        if to == '/'
            return
        endif
        if this._expanded_paths->has_key(from)
            var newdir = to->slice(0, to->strcharlen() - 1)
            this._expanded_paths[newdir] = null_string
        endif
    enddef


    def RaiseRoot()
        if this.root.path == '/'
            return
        endif
        var higher_root = FileTreeNode.new(this.root.path->fnamemodify(':h'))
        this._EnsureExpand(higher_root)
        for [i, child] in higher_root.children->items()
            if (<FileTreeNode>child).path == (<FileTreeNode>this.root).path
                higher_root.children[i] = this.root
                break
            endif
        endfor
        this.root = higher_root
    enddef


    def ToggleHidden()
        this._show_hidden = !this._show_hidden
    enddef


    def GetPrettyFormatLines(): list<dict<any>>
        this._text_list = []
        this._PrettyFormatLineRecur(this.root, 0)
        return this._text_list
    enddef


    def _FormatWithProp(text: string,
                        prop: string,
                        indents: number = 0): dict<any>
        return {text: '  '->repeat(indents) .. text,
                props: [{col: 2 * indents + 1, length: text->len(), type: prop}]}
    enddef


    def _PrettyFormatLineRecur(node: FileTreeNode, depth: number)
        var tail = node.path->fnamemodify(':t')
        if !this._show_hidden && tail[0] == '.' && node.path != getcwd()
            return
        endif
        var roflag = node.path->filewritable() == 0 ? ' [RO]' : ''
        var islink = node.path->getftype() == 'link'
        var linksto = islink ? $' -> {node.path->resolve()}' : ''
        var indent = '  '->repeat(depth)
        if node.path->isdirectory()
            var dir_prop = islink ? 'prop_poplar_tree_link_file' : 'prop_poplar_tree_dir'
            dir_prop = node.path ==? getcwd() ? 'prop_poplar_tree_cwd' : dir_prop
            var dirname = node.path ==? getcwd() ? node.path : tail
            if this._expanded_paths->has_key(node.path)
                this._text_list->add(this._FormatWithProp(
                    $'{g:poplar.diropensymb} {dirname}/{linksto}', dir_prop, depth))
                for child in node.children
                    this._PrettyFormatLineRecur(child, depth + 1)
                endfor
            else
                this._text_list->add(this._FormatWithProp(
                    $'{g:poplar.dirclosedsymb} {dirname}/{linksto}', dir_prop, depth))
            endif
        elseif node.path->executable()
            var prop = islink ? 'prop_poplar_tree_link_file' : 'prop_poplar_tree_exec_file'
            this._text_list->add(this._FormatWithProp($'  {tail}*{roflag}{linksto}', prop, depth))
        else
            var prop = islink ? 'prop_poplar_tree_link_file' : 'prop_poplar_tree_file'
            this._text_list->add(this._FormatWithProp($'  {tail}{roflag}{linksto}', prop, depth))
        endif
    enddef


    def GetNodeAtDisplayIndex(idx: number): FileTreeNode # 0-index
        var ct = 0
        var found: FileTreeNode = null_object
        def GetNodeRecur(node: FileTreeNode)
            if ct <= idx
                if !this._show_hidden && node.path->fnamemodify(':t')[0] == '.' && node.path != getcwd()
                    return
                endif
                ct += 1
                found = node
                if this._expanded_paths->has_key(node.path)
                    for child in node.children
                        GetNodeRecur(child)
                    endfor
                endif
            endif
        enddef
        GetNodeRecur(this.root)
        return found
    enddef


    def ToggleDir(node: FileTreeNode)
        if !node.path->isdirectory()
            throw $'fatal: tried to ToggleDir on nondir: {node.path}'
        endif
        if this._expanded_paths->has_key(node.path)
            unlet this._expanded_paths[node.path]
        else
            this._expanded_paths[node.path] = null_string
        endif
        if node.children == null_list
            var fmt_path = node.path == '/' ? node.path : $'{node.path}/'
            var listings = $'{fmt_path}.*'
                    ->glob(true, true)
                    ->filter((_, p) => p !~ '.*/\.\+$')
                    + $'{fmt_path}*'->glob(true, true)
            var dirs = listings
                    ->copy()
                    ->filter((_, p) => p->isdirectory())
                    ->mapnew((_, p) => FileTreeNode.new(p))
            var nondirs = listings
                    ->filter((_, p) => !p->isdirectory())
                    ->mapnew((_, p) => FileTreeNode.new(p))
            node.children = dirs + nondirs
        endif
    enddef


    def _EnsureExpand(node: FileTreeNode)
        this.ToggleDir(node)
        if !this._expanded_paths->has_key(node.path)
            this._expanded_paths[node.path] = null_string
        endif
    enddef

endclass
