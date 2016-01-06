syn clear
syn case match

hi link eyNonword Operator
hi link eyEscapeSeq SpecialChar
hi link eyControl Statement
hi link eyMath Function
hi link eyMacro Function
hi link eyOther Function
hi link eyNumber Constant
hi link eyString Constant
hi link eyAutoquoteWord Constant
hi link eyModule Constant
hi link eyComment Comment
hi link eyWord Normal

syn match eyNonword /[^a-zA-Z0-9 ]\+/
syn match eyWord /[a-zA-Z0-9]\+/
syn match eyAutoquoteWord /[a-zA-Z0-9][^ ]*/ contained
syn match eyCombined /[^a-zA-Z0-9 ]\+[a-zA-Z0-9][^ ]*/ contains=eyNonWord,eyAutoquoteWord
syn match eyNumber /[0-9]\+/
syn region eyString start=/"/ end=/"/ contains=eyEscapeSeq
syn match eyEscapeSeq /\\["n\\']/ contained
syn keyword eyControl rep include dump die each loop exe
syn keyword eyMath regex range
syn keyword eyMath sig len cat dearray dom keys
syn keyword eyMath add sub mul div mod and nand or xor nxor nor band bnand bor bxor bnxor bnor
syn keyword eyMath eq neq lt le gt ge gcd neg not bnot abs streq
syn keyword eyOther quoted deff defv defq defvs deffs defvt defft defvst deffst defvc deffc defvd deffd defm defms defmt defmst defmc defmd
syn keyword eyOther code sym blk
syn keyword eyModule sys
syn match eyComment /#.*$/
