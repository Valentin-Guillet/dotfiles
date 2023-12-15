
syn match cppSymbol            "->\|[*+=&|^!-]"
syn match cppSymbol            "/\ze[^*/]"
syn match cppSymbol            "\s[<>][ \t\n=]"
syn match cppSymbol            "\s\(<<\|>>\)\s"
syn match cppStructName        "\v(struct\s+)@<=[a-zA-Z0-9_]+"
syn match cppStructName        "\v(enum( class)?\s+)@<=[a-zA-Z0-9_]+"

hi def link cppSymbol          Conditional
hi def link cppStructName      Function
