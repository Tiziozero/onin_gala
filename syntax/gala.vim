syn keyword galaKeyword fn struct return if else otherwise
syn keyword galaBuiltin cast sizeof alignof
syn keyword galaType int flt
syn match galaFunction /\<[A-Za-z_][A-Za-z0-9_]*\ze\s*(/

syn match galaNumber "\d\+"

hi def link galaKeyword Keyword
hi def link galaBuiltin Special
hi def link galaType Type
hi def link galaNumber Number
hi def link galaFunction Function
