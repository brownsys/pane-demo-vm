" Vim syntax file
" Language: FlowLog

if exists("b:current_syntax")
  finish
endif

syn region flowlogParens start="(" end=")" fold transparent

" Keywords
syn keyword flowlogLanguageKeywords TABLE EVENT OUTGOING INCOMING INCLUDE
syn keyword flowlogLanguageKeywords DO ON DELETE INSERT FROM WHERE AND NOT OR INTO THEN TIMEOUT
syn keyword flowlogLanguageKeywords and not ANY

" Comments
syn keyword flowlogTodo contained TODO FIXME XXX NOTE
syn match  flowlogComment "\/\/.*$" contains=flowlogTodo
syn region flowlogC_Comment start="\/\*" end="\*\/" contains=flowlogTodo

" Types
syn keyword flowlogType  int int48 string ipaddr macaddr switchid portid

" Constants
syn match flowlogNumber '\d\+' " Integer
syn match flowlogNumber '0x\x\+' " Hex number

let b:current_syntax = "flowlog"

hi def link flowlogTodo Todo
hi def link flowlogComment  Comment
hi def link flowlogC_Comment Comment
hi def link flowlogLanguageKeywords Statement
hi def link flowlogType Type
hi def link flowlogNumber  Constant
