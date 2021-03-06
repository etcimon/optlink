		TITLE DSEGMOD - Copyright (c) 1994 by SLR Systems

		INCLUDE MACROS
		INCLUDE	SEGMENTS

		PUBLIC	DEFINE_SEGMOD,DEFINE_SEGMOD_0


		.DATA

		EXTERNDEF	SEG_COMBINE:BYTE,CLASS_TYPE:BYTE,CLASS_PLTYPE:BYTE,FILE_PLINK_FLAGS:BYTE,SEG_ALIGN:BYTE
		EXTERNDEF	CODEVIEW_PLTYPE:BYTE

		EXTERNDEF	CLASS_SECTION_GINDEX:DWORD,CURNMOD_GINDEX:DWORD,SEG_SECTION_GINDEX:DWORD
		EXTERNDEF	CODEVIEW_SECTION_GINDEX:DWORD,DATA_SECTION_GINDEX:DWORD,MOD_SECTION_GINDEX:DWORD
		EXTERNDEF	FILE_SECTION_GINDEX:DWORD,FIRST_SECTION_GINDEX:DWORD,CV_NUL_SYMBOLS_SEGMOD:DWORD
		EXTERNDEF	CV_NUL_TYPES_SEGMOD:DWORD,MOD_CV_TYPES_SEGMOD:DWORD,MOD_CV_SYMBOLS_SEGMOD:DWORD
		EXTERNDEF	MOD_CV_NAMES_SEGMOD:DWORD,CV_NUL_NAMES_SEGMOD:DWORD,SEG_LEN:DWORD,SEG_FRAME:DWORD

		EXTERNDEF	SEGMENT_GARRAY:STD_PTR_S,SEGMOD_GARRAY:STD_PTR_S


		.CODE	PASS1_TEXT

		EXTERNDEF	GET_SEGMENT_ENTRY:PROC


DEFINE_SEGMOD_0	LABEL	PROC

		XOR	EAX,EAX

		MOV	SEG_LEN,EAX

DEFINE_SEGMOD	PROC
		;
		;RETURNS EAX IS GINDEX, ECX IS PHYSICAL
		;
		CALL	GET_SEGMENT_ENTRY	;EAX IS GINDEX, ECX PHYS
		ASSUME	ECX:PTR SEGMENT_STRUCT

		PUSHM	EDI,EBX

		MOV	EDI,ECX
		ASSUME	EDI:PTR SEGMENT_STRUCT
		MOV	BL,[ECX]._SEG_TYPE

		MOV	EDX,EAX
		MOV	CLASS_TYPE,BL

		AND	BL,MASK SEG_CV_TYPES1 + MASK SEG_CV_SYMBOLS1
		JNZ	CV_SEGMODS
CV_SEGMODS_RET:

		MOV	EAX,SIZE SEGMOD_STRUCT
		SEGMOD_POOL_ALLOC		;EAX IS PHYS

		MOV	EBX,EAX
		INSTALL_POINTER_GINDEX	SEGMOD_GARRAY
		MOV	ECX,EAX			;ECX IS SEGMOD GINDEX

		XOR	EAX,EAX
		ASSUME	EBX:PTR SEGMOD_STRUCT

		MOV	[EBX]._SM_BASE_SEG_GINDEX,EDX
		MOV	[EBX]._SM_NEXT_SEGMOD_GINDEX,EAX

		MOV	[EBX]._SM_START,EAX
		MOV	[EBX]._SM_FIRST_DAT,EAX

		MOV	[EBX]._SM_COMDAT_LINK,EAX
		MOV	[EBX]._SM_FLAGS_2,AL

		MOV	EAX,CURNMOD_GINDEX
		MOV	DL,SEG_COMBINE

		MOV	[EBX]._SM_MODULE_CSEG_GINDEX,EAX
		CMP	DL,SC_STACK

		MOV	AL,SEG_ALIGN
		JNZ	L1$

		CMP	AL,SA_DWORD
		JZ	L0$

		CMP	AL,SA_PARA
		JA	L1$
L0$:
		MOV	AL,SA_PARA
L1$:
		MOV	AH,[EDI]._SEG_MAX_ALIGN
		MOV	[EBX]._SM_ALIGN,AL
		;
		;NEED MAXIMUM ALIGN THIS SEGMENT
		;
		CMP	AH,AL
		JA	SMA_1
		;
		;AL IS LARGER, USE IT UNLESS AL=5 AND [SI] IS 3 OR 4
		;
		CMP	AL,5
		JNZ	SMA_NEW

		CMP	AH,3
		JAE	SMA_DONE

		JMP	SMA_NEW

CV_SEGMODS:
		MOV	EAX,SEG_LEN

		TEST	EAX,EAX
		JNZ	CV_SEGMODS_RET

		JMP	DO_CV_NUL

IS_STACK:
		ADD	EAX,3			;EVEN DWORD SIZE

		AND	AL,0FCH
		JMP	IS_STACK_RET

SMA_1:
		;
		;AL IS SMALLER, USE OLD UNLESS OLD=5 AND AL IS 3 OR 4
		;
		CMP	AH,5
		JNZ	SMA_DONE

		CMP	AL,3
		JB	SMA_DONE
SMA_NEW:
		MOV	[EDI]._SEG_MAX_ALIGN,AL
SMA_DONE:
		MOV	DL,CLASS_TYPE
		CMP	AL,SA_ABSOLUTE

		MOV	[EBX]._SM_FLAGS,DL
		JZ	YES_ASEG

		MOV	DL,[EDI]._SEG_COMBINE
		MOV	EAX,SEG_LEN
		;
		;IF STACK, MAKE SURE OF DWORD LENGTH...
		;
		CMP	DL,SC_STACK
		JZ	IS_STACK
IS_STACK_RET:
		TEST	EAX,EAX
		JZ	NOT_STACK

		OR	[EDI]._SEG_32FLAGS,MASK SEG32_NONZERO
NOT_STACK:
		MOV	[EBX]._SM_LEN,EAX
NOT_STACK1:
		;
		;NOW STICK SEGMOD IN LIST FROM DI
		;
		MOV	EAX,[EDI]._SEG_LAST_SEGMOD_GINDEX
		MOV	[EDI]._SEG_LAST_SEGMOD_GINDEX,ECX

		TEST	EAX,EAX
		JZ	L2$
		;
		;NOT FIRST, SO PUT AT END OF LIST
		;
		CONVERT	EAX,EAX,SEGMOD_GARRAY
		ASSUME	EAX:PTR SEGMOD_STRUCT

		MOV	[EAX]._SM_NEXT_SEGMOD_GINDEX,ECX
L3$:
if	fg_plink
		;
		;ASSIGN TO A SECTION?
		;
		MOV	EAX,SEG_SECTION_GINDEX
		MOV	EDX,OFF SEG_SECTION_GINDEX	;IF SECT DEFINED FOR SEGMENT
		TEST	EAX,EAX		;USE IT
		JNZ	L5$
endif
if	any_overlays
		MOV	EAX,CLASS_SECTION_GINDEX
		MOV	EDX,OFF CLASS_SECTION_GINDEX	;IF SECT DEFINED FOR CLASS
		TEST	EAX,EAX		;USE IT
		JNZ	L5$
endif
		MOV	AL,CLASS_TYPE
		MOV	EDX,OFF CODEVIEW_SECTION_GINDEX

		TEST	AL,MASK SEG_CV_TYPES1 + MASK SEG_CV_SYMBOLS1
		JNZ	L51$
if	any_overlays
		MOV	AL,CLASS_PLTYPE
		MOV	EDX,OFF DATA_SECTION_GINDEX 	;IF NOT OVERLAYABLE, USE DATA
		TEST	EAX,MASK SEG_OVERLAYABLE
		JZ	L5$			;SECTION
  if	fg_plink
		;
		;IS MODULE SECTION ASSIGNED?
		;
		MOV	EAX,MOD_SECTION_GINDEX
		MOV	EDX,OFF MOD_SECTION_GINDEX	;IF SECT DEFINED FOR MODULE
		TEST	EAX,EAX		;USE IT
		JNZ	L5$
  endif
  if	alloc_support
		;
		;USE FILENAME SECTION (UNLESS ALLOCATING)
		;
		TEST	FILE_PLINK_FLAGS,MASK LIB_ALLOCATE
		JNZ	L59$
  endif
		MOV	EAX,[EBX]._SM_LEN
		MOV	EDX,OFF FILE_SECTION_GINDEX
		TEST	EAX,EAX
		JZ	L59$
else
		MOV	EDX,OFF FIRST_SECTION_GINDEX
endif
L5$:
		OR	[EBX]._SM_PLTYPE,MASK SECTION_ASSIGNED
		MOV	EAX,[EDX]

		MOV	DL,[EDX+4]
		MOV	[EBX]._SM_SECTION_GINDEX,EAX

		OR	[EBX]._SM_PLTYPE,DL
L59$:
		MOV	EAX,ECX
		MOV	ECX,EBX

		POPM	EBX,EDI
		;
		;RETURN EAX LOG, ECX:PHYS
		;
		RET

L51$:
		;
		;HERE IF ANY DEBUG SEGMENT INCLUDED
		;
		SETT	NEED_MDB_RECORD

		TEST	AL,MASK SEG_CV_TYPES1
		JZ	L52$

		TEST	AL,MASK SEG_CV_SYMBOLS1
		JNZ	L53$

		MOV	MOD_CV_TYPES_SEGMOD,ECX
		JMP	L5$

L52$:
		MOV	MOD_CV_SYMBOLS_SEGMOD,ECX
		JMP	L5$

L53$:
		MOV	MOD_CV_NAMES_SEGMOD,ECX
		JMP	L5$

L2$:
		ASSUME	EDI:PTR SEGMENT_STRUCT

		MOV	[EDI]._SEG_FIRST_SEGMOD_GINDEX,ECX
		JMP	L3$

YES_ASEG:
		;
		;STORE ASEG ADDRESS IN BASE AND CURRENT
		;
		MOV	EAX,SEG_FRAME
		MOV	EDX,SEG_LEN

		MOV	[EBX]._SM_START,EAX
		ADD	EAX,EDX

		MOV	[EBX]._SM_LEN,EAX
		JMP	NOT_STACK1

DO_CV_NUL:
		;
		;RETURN EAX IS GINDEX, ECX IS PHYS
		;
		TEST	BL,MASK SEG_CV_TYPES1
		JZ	TEST_CV_SYMBOLS

		AND	BL,MASK SEG_CV_SYMBOLS1
		JNZ	TEST_CV_NAMES

		MOV	EAX,CV_NUL_TYPES_SEGMOD

		TEST	EAX,EAX
		JNZ	RETURN_CV_NUL

		POP	EBX
		CALL	CREATE_CV_NUL

		POP	EDI
		MOV	CV_NUL_TYPES_SEGMOD,EAX

		RET

TEST_CV_NAMES:
		MOV	EAX,CV_NUL_NAMES_SEGMOD

		TEST	EAX,EAX
		JNZ	RETURN_CV_NUL

		POP	EBX
		CALL	CREATE_CV_NUL

		POP	EDI
		MOV	CV_NUL_NAMES_SEGMOD,EAX

		RET

TEST_CV_SYMBOLS:
		MOV	EAX,CV_NUL_SYMBOLS_SEGMOD

		TEST	EAX,EAX
		JNZ	RETURN_CV_NUL

		POP	EBX
		CALL	CREATE_CV_NUL

		POP	EDI
		MOV	CV_NUL_SYMBOLS_SEGMOD,EAX

		RET

RETURN_CV_NUL:
		POPM	EBX,EDI

		CONVERT	ECX,EAX,SEGMOD_GARRAY

		RET

DEFINE_SEGMOD	ENDP


CREATE_CV_NUL	PROC
		;
		;GET A SEGMOD EVERYONE CAN USE AS TO-BE-IGNORED
		;
		MOV	EAX,SIZE SEGMOD_STRUCT
		SEGMOD_POOL_ALLOC		;ES:DI IS PHYS, AX IS LOG

		MOV	EBX,EAX
		INSTALL_POINTER_GINDEX	SEGMOD_GARRAY
		MOV	ECX,EAX			;CX IS SEGMOD GINDEX

		XOR	EAX,EAX

		MOV	[EBX]._SM_BASE_SEG_GINDEX,EDX
		MOV	[EBX]._SM_NEXT_SEGMOD_GINDEX,EAX

		MOV	[EBX]._SM_START,EAX
		MOV	[EBX]._SM_LEN,EAX

		MOV	[EBX]._SM_FIRST_DAT,EAX
		MOV	[EBX]._SM_FLAGS_2,AL

		MOV	EAX,CURNMOD_GINDEX
		MOV	DL,SEG_ALIGN

		MOV	[EBX]._SM_MODULE_CSEG_GINDEX,EAX
		MOV	EAX,CODEVIEW_SECTION_GINDEX

		MOV	[EBX]._SM_ALIGN,DL
		MOV	[EBX]._SM_SECTION_GINDEX,EAX

		MOV	AL,CODEVIEW_PLTYPE
		MOV	DH,[EBX]._SM_PLTYPE

		OR	AL,MASK SECTION_ASSIGNED
		MOV	DL,CLASS_TYPE

		OR	AL,DH
		MOV	[EBX]._SM_FLAGS,DL

		MOV	[EBX]._SM_PLTYPE,AL

		MOV	EAX,ECX
		MOV	ECX,EBX
		;
		;RETURN AX:BX LOG, DX:PHYS
		;
		RET

CREATE_CV_NUL	ENDP


		END

