syn keyword galaKeyword fn struct return if else otherwise extern while for
syn keyword galaBuiltin cast transmute sizeof alignof true false any len
syn keyword galaType int flt bool rawptr byte rune string void
syn match galaFunction /\<[A-Za-z_][A-Za-z0-9_]*\ze\s*(/
syn region galaString start=/"/ skip=/\\|\"/ end=/"/
syn match galaNumber "\<\d\+\>"

syn match galaComment "//.*$"
syn region galaComment start="/\*" end="\*/"

hi def link galaKeyword Keyword
hi def link galaBuiltin Special
hi def link galaType Type
hi def link galaNumber Number
hi def link galaFunction Function
hi def link galaString String
hi def link galaComment Comment
