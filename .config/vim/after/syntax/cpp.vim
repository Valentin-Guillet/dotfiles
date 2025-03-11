
syntax match cppSymbol            "->\|[*+=&|^!-]"
syntax match cppSymbol            "/\ze[^*/]"
syntax match cppSymbol            "\s[<>][ \t\n=]"
syntax match cppSymbol            "\s\(<<\|>>\)\s"
syntax match cppStructName        "\v(struct\s+)@<=[a-zA-Z0-9_]+"
syntax match cppStructName        "\v(enum( class)?\s+)@<=[a-zA-Z0-9_]+"

highlight link cppSymbol          Conditional
highlight link cppStructName      Function
highlight link cppSTLnamespace    NONE
