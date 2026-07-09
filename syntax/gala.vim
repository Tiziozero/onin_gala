syn keyword galaKeyword fn struct return if else otherwise extern
syn keyword galaBuiltin cast sizeof alignof true false
syn keyword galaType int flt bool rawptr byte rune
syn match galaFunction /\<[A-Za-z_][A-Za-z0-9_]*\ze\s*(/

syn match galaNumber "\<\d\+\>"

hi def link galaKeyword Keyword
hi def link galaBuiltin Special
hi def link galaType Type
hi def link galaNumber Number
hi def link galaFunction Function
