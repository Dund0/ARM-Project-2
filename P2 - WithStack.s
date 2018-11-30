.text

@Read Command Input
	LDR	R0,=InCommandFileName
	MOV R1,#0
	SWI SWI_OPEN
	BCS CommandFileError
	LDR R1,=InFileHandle
	STR R0,[R1]	
	
	LDR R0,=InFileHandle
	LDR R0,[R0]
	SWI SWI_RDINT
	BCS InputError
	
	CMP R0,#0
	BLT InputError
	BGT Decrypt
	B	Encrypt
	
Encrypt:
	LDR R0,=EncMessageFileName
	MOV R1,#1
	SWI SWI_OPEN
	BCS InputError
	LDR R1,=OutFileHandle
	STR R0,[R1]

	LDR R0,=InFileHandle
	LDR R0,[R0]
	SWI SWI_RDINT
	BCS KeyError
	
	CMP R0,#1
	BLT InputKeyError
	CMP R0,#127
	BGT InputKeyError
	
	MOV R9,R0
	
	LDR R0,=InFileHandle
	LDR R0,[R0]
	SWI SWI_CLOSE
	
	@allocate memory
	MOV R0,#1000
	SWI SWI_MEALLOC
	LDR r1,=OutputMessage
	STR r0,[r1]
	STR r0,=OutputLocation
	
	MOV R0,#1000
	SWI SWI_MEALLOC
	LDR r1,=InputMessage
	STR r0,[r1]
	STR r0,=InputLocation
	
	@read string
	LDR	R0,=InMessageFileName
	MOV R1,#0
	SWI SWI_OPEN
	BCS MessageFileError
	LDR R1,=InFileHandle
	STR R0,[R1]
	
	LDR R0,=InFileHandle
	LDR R0,[R0]
	LDR R1,=InputLocation
	MOV R2,#1000
	SWI SWI_RDSTR
	BCS MessageError
	
	MOV R1,R0
	MOV R0,#0
	
	LDR R2,=InputLocation
	LDR R3,=OutputLocation

@Encrypt Message	
EncLoop:
	
	LDRB R4,[R2,R0]
	ADD R0,R0,#1
	
	STMFD R13!,{R4}
	
	CMP R0,R1
	BLT EncLoop
	SUBGE R0,R0,#1
	BLGE EOR
	BL Print
	B endif

Decrypt:
	CMP R0,#1
	BGT InputError

	LDR R0,=DecMessageFileName
	MOV R1,#1
	SWI SWI_OPEN
	BCS OutputFileError
	LDR R1,=OutFileHandle
	STR R0,[R1]

	LDR R0,=InFileHandle
	LDR R0,[R0]
	SWI SWI_RDINT
	BCS KeyError
	
	CMP R0,#1
	BLT InputKeyError
	CMP R0,#127
	BGT InputKeyError
	
	MOV R9,R0
	
	LDR R0,=InFileHandle
	LDR R0,[R0]
	SWI SWI_CLOSE
	
	@allocate memory
	MOV R0,#1000
	SWI SWI_MEALLOC
	LDR r1,=OutputMessage
	STR r0,[r1]
	STR r0,=OutputLocation
	
	MOV R0,#1000
	SWI SWI_MEALLOC
	LDR r1,=InputMessage
	STR r0,[r1]
	STR r0,=InputLocation
	
	@read string
	LDR	R0,=EncMessageFileName
	MOV R1,#0
	SWI SWI_OPEN
	BCS OutputError
	LDR R1,=InFileHandle
	STR R0,[R1]
	
	LDR R0,=InFileHandle
	LDR R0,[R0]
	LDR R1,=InputLocation
	MOV R2,#1000
	SWI SWI_RDSTR
	BCS MessageError
	
	MOV R1,R0
	MOV R0,#0
	
	LDR R2,=InputLocation
	LDR R3,=OutputLocation

@Decrypt Message
DecLoop:

	LDRB R4,[R2,R0]
	ADD R0,R0,#1
	
	STMFD R13!,{R4}
	
	CMP R0,R1
	BLT DecLoop
	SUBGE R0,R0,#1
	BLGE EOR
	BL Print
	B endif

@Print the string to file
Print:
	LDR R0,=OutFileHandle
	LDR R0,[R0]
	LDR R1,=OutputMessage
	LDR R1,[R1]
	SWI SWI_PRSTR
	BX	LR

@Encryption algorithm
EOR:
	LDMFD R13!,{R4}
	
	CMP R4,#0
	EORNE R4,R4,R9
	STRB R4,[R3,R0]
	SUB R0,R0,#1
	
	CMP R0,#0
	BGE EOR
	
	BX LR

@Error ouputs
CommandFileError:
	LDR	R0,=CommandFileErrorM
	SWI	SWI_DISTR
	B	endif
	
InputError:
	LDR	R0,=CommandFileNoInput
	SWI	SWI_DISTR
	B	endif
	
KeyError:
	LDR R0,=CommandFileNoKey
	SWI SWI_DISTR
	B	endif
	
InputKeyError:
	LDR R0,=CommandFileNoKey
	SWI SWI_DISTR
	B	endif
	
MessageFileError:
	LDR R0,=MessageFileErrorM
	SWI SWI_DISTR
	B	endif

OutputError:
	LDR	R0,=EncryptedFileError
	SWI	SWI_DISTR
	B	endif
	
OutputFileError:
	LDR	R0,=DecryptionFileE
	SWI	SWI_DISTR
	B	endif
	
MessageError:
	LDR R0,=NoMessageInFile
	SWI SWI_DISTR
	B	endif
	
@close the files and exit
endif:
	LDR R0,=InFileHandle
	LDR R0,[R0]
	SWI SWI_CLOSE
	LDR R0,=OutFileHandle
	LDR R0,[R0]
	SWI SWI_CLOSE
	SWI SWI_DALLOC
	SWI SWI_EXIT



.bss
InCommandFileName:	.asciz "inputCommand.txt"
InMessageFileName:	.asciz "messageInput.txt"
EncMessageFileName:	.asciz "EncryptedMessage.txt"
DecMessageFileName:	.asciz "DecryptedMessage.txt"
CommandFileErrorM:	.asciz "Unable to open command file\n"
CommandFileNoInput:	.asciz "No valid input command\n"
CommandFileNoKey:	.asciz "No valid key input\n"
MessageFileErrorM:	.asciz "Unable to open message file\n"
EncryptedFileError:	.asciz "Unable to open Encrypted File\n"
DecryptionFileE:	.asciz "Unable to create DecryptionFile\n"
NoMessageInFile:	.asciz "No message in file\n"
ReadErrorM:			.asciz "No input values\n"
OutFileErrorM:		.asciz "Unable to open output file\n"
NullCharacter:		.asciz ""

.align
InFileHandle:		.word 0
.align
OutFileHandle:		.word 0
InputMessage:		.word 0
OutputMessage:		.word 0

InputLocation:		.word 0
OutputLocation:		.word 0

.data
.equ SWI_DICHR,   0x00 @input r0: character, prints character
.equ SWI_DISTR,   0x02 @input r0: address of a null terminated ASCII string, output: 0x69, Display String on Stdout
.equ SWI_EXIT,    0x11 @halts execution
.equ SWI_MEALLOC, 0x12 @input r0: block size in bytes, output r0: address of block, allocates block of memory to heap
.equ SWI_DALLOC,  0x13 @deallocates all heap blocks
.equ SWI_OPEN,    0x66 @input r0: file name, r1: mode, output r0: file handle(-1 returned if not opened), mode: 0 for input, 1 for output, 2 for appending
.equ SWI_CLOSE,   0x68 @input r0: file handle, closes file
.equ SWI_PRSTR,   0x69 @input r0: file handleor Stdout, r1: address of a null terminated ASCII string, write String to File or Stdout
.equ SWI_RDSTR,   0x6a @input r0: file handle,  r1: destination address, r2: max bytes to store, output: r0: number of  bytes stored, read String from a File
.equ SWI_PRINT,   0x6b @input r0: file handle, r1: integer, Write Integer to a File
.equ SWI_RDINT,   0x6c @input r0: file handle, output r0: the integer
.equ SWI_TIMER,   0x6d @output: r0: the number of  ticks (milliseconds), Get the current time(ticks)
.equ ARRAY_MAX_SIZE,	1000
