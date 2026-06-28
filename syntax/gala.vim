syn keyword galaKeyword fn struct return if else otherwise
syn match galaNumber "\d\+"
syn keyword galaType int flt

hi def link galaKeyword Keyword
hi def link galaNumber Number
hi def link galaType Type
" hi galaType guifg=#FF00FF ctermfg=Magenta
