vim9script


class FileTreeNode # {{{
    var path: string
    public var children: list<FileTreeNode> = null_list

    def new(this.path)
    enddef

endclass # }}}


export class FileTree
    var root: any
    var show_hidden: bool
    var text_list: list<string>

    def new(root_path: string)
        this.root = FileTreeNode.new(root_path)
    enddef


    def GetTextList(): list<string>
        this.GetTextListRecurse(this.root, 0)
        return this.text_list
    enddef


    def GetTextListRecurse(node: any, depth: number)
        var indent = '  '->repeat(depth)
        var base = '  ' .. this._GetBaseName(node.path)
        if node.path->isdirectory() && node.children != null
            base = '▾' .. base[1 :]
        elseif node.path->isdirectory() && node.children == null
            base = '▸' .. base[1 :]
        endif
        this.text_list->add(indent .. base)
        for child in node.children
            this.GetTextListRecurse(child, depth + 1)
        endfor
    enddef


    def _GetBaseName(path: string): string
        var base = path->fnamemodify(':t')
        return path->isdirectory() ? base .. '/' : base
    enddef


    def ToggleDir(node: any)
        assert_true(node.path->isdirectory(),
            $'{node.path} not a directory!')
        if node.children == null_list
            var listings = $'{node.path}/*'->glob(true, true)
            if this.show_hidden
                listings += $'{node.path}/.*'
                    ->glob(true, true)
                    ->filter((_, p) => p =~ '.*/\.\+$')
            endif
            var dirs = listings
                ->copy()
                ->filter((_, p) => p->isdirectory())
                ->mapnew((_, p) => FileTreeNode.new(p))
            var nondirs = listings
                ->filter((_, p) => !p->isdirectory())
                ->mapnew((_, p) => FileTreeNode.new(p))
            node.children = dirs + nondirs
        else
            node.children = null_list
        endif
    enddef

endclass
