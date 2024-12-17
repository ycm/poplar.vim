vim9script

class FileTreeNode # {{{
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


    def HardRefresh() # <TODO> make this open previously opened dirs
        this.root = FileTreeNode.new(this.root.path)
        this._expanded_paths = {} # <HACK> failsafe
        this._EnsureExpand(this.root)
    enddef


    def ChangeRoot(node: FileTreeNode)
        if !node.path->isdirectory() || node == this.root
            return
        endif
        this.root = node
        this._EnsureExpand(this.root)
    enddef


    def RaiseRoot()
        if this.root.path == '/'
            return
        endif
        var higher_root = FileTreeNode.new(this.root.path->fnamemodify(':h'))
        this._EnsureExpand(higher_root)
        for [i, child] in higher_root.children->items()
            if child.path == this.root.path
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
        return {
            text: '  '->repeat(indents) .. text,
            props: [{
                col: 2 * indents + 1,
                length: text->len(),
                type: prop
            }]
        }
    enddef


    def _PrettyFormatLineRecur(node: FileTreeNode, depth: number)
        var tail = node.path->fnamemodify(':t')
        if !this._show_hidden && tail[0] == '.'
            return
        endif
        var indent = '  '->repeat(depth)
        if node.path->isdirectory()
            if this._expanded_paths->has_key(node.path)
                this._text_list->add(this._FormatWithProp(
                    $'▾ {tail}/', 'prop_poplar_tree_dir', depth))
                for child in node.children
                    this._PrettyFormatLineRecur(child, depth + 1)
                endfor
            else
                this._text_list->add(this._FormatWithProp(
                    $'▸ {tail}/', 'prop_poplar_tree_dir', depth))
            endif
        elseif node.path->executable()
            this._text_list->add(this._FormatWithProp(
                $'  {tail}*', 'prop_poplar_tree_exec_file', depth))
        else
            this._text_list->add(this._FormatWithProp(
                $'  {tail}', 'prop_poplar_tree_file', depth))
        endif
    enddef


    def GetNodeAtDisplayIndex(idx: number): FileTreeNode # 0-index
        var ct = 0
        var found: FileTreeNode = null_object
        def GetNodeRecur(node: FileTreeNode)
            if ct <= idx
                if !this._show_hidden && node.path->fnamemodify(':t')[0] == '.'
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
