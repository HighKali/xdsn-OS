.equ	RAMSTART	0x4000
jp	test

#include "core.asm"
#include "lib/util.asm"
#include "zasm/util.asm"
#include "zasm/const.asm"
.equ	SYM_RAMSTART	RAMSTART
#include "zasm/symbol.asm"

testNum:	.db 1

sFOO:		.db "FOO", 0
sFOOBAR:	.db "FOOBAR", 0
sOther:		.db "Other", 0

test:
	ld	sp, 0xffff

	; Check that we compare whole strings (a prefix will not match a longer
	; string).
	call	symInit
	ld	hl, sFOOBAR
	ld	de, 42
	call	symRegisterGlobal
	jp	nz, fail
	ld	hl, sFOO
	ld	de, 43
	call	symRegisterGlobal
	jp	nz, fail

	ld	hl, sFOO
	call	symFindVal		; don't match FOOBAR
	jp	nz, fail
	ld	a, d
	or	a
	jp	nz, fail
	ld	a, e
	cp	43
	jp	nz, fail
	call	nexttest

	ld	hl, sOther
	call	symFindVal
	jp	z, fail
	call	nexttest

	; success
	xor	a
	halt

nexttest:
	ld	hl, testNum
	inc	(hl)
	ret

fail:
	ld	a, (testNum)
	halt




