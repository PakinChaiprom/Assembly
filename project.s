section .data ;Jeno
	LF      equ     10
	NULL    equ     0
	EXIT_SUCCESS equ 0 ; success code
	STDIN   equ     0
	STDOUT  equ     1
	STDERR  equ     2
	SYS_read  equ	0	
	SYS_write equ   1
	SYS_exit equ    60
	msg     db      "Enter statement : ", NULL
	newLine db      LF, NULL
	inputLen equ 32
	op1 dq 0
	op2 dq 0
	operator db 0
	err db "Error", NULL

section .bss ;Jeno
       	inbuffer	resb	100	;input buffer
	outbuffer	resb	8

section .text ;Jeno
global _start 
_start:
	mov rdi, newLine 
	call printString

	mov rdi, msg
	call printString

	mov rax, SYS_read
	mov rdi, STDIN
	mov rsi, inbuffer
	mov rdx, inputLen
	syscall

	mov rsi, inbuffer
	mov rbx, 0

	call readOp
	mov qword[op1], rbx
	
	mov rcx, 0
	call readOperator
	
	mov rbx, 0
	call readOp
	mov qword[op2], rbx

	mov rax, 0
	mov rax, qword[op1]
	mov rbx, 0
	mov rbx, qword[op2]
	cmp rcx, '+'
	je doAdd
	cmp rcx, '-'
	je doSub
	cmp rcx, '*' 
	je doMul
	cmp rcx, '/'
	je doDiv

doAdd: ;Mark
	add rax, rbx
	jmp printResult

doSub: ;Mark
	sub rax, rbx
	cmp rax, 0
	jl error
	jmp printResult
	
doMul: ;Mark
	imul rax, rbx
	jmp printResult

doDiv: ;Mark
	mov rdx, 0
	div rbx
	jmp printResult

error: ;Jeno
	mov rdi, err
	call printString
	mov rdi, newLine
	call printString
	jmp exit
	
printResult: ;Phoom
	push rsi
	mov rsi, outbuffer+7
	mov r9, 0
.convertLoop:
	mov rdx, 0
	mov rcx, 10
	div rcx
	add dl, '0'
	dec rsi
	mov [rsi], dl

	inc r9
	cmp rax, 0
	jne .convertLoop

	mov rax, SYS_write
	mov rdi, STDOUT
	mov rdx, r9
	syscall

	mov rdi, newLine
	call printString

	pop rsi
	jmp exit

exit:
	mov rax, SYS_exit
	mov rdi, EXIT_SUCCESS
	syscall
	
readOperator: ;Mark
.skipspace:
	movzx rax, byte[rsi]
	cmp al, ' '
	jne .foundOperator
	inc rsi
	jmp .skipspace
.foundOperator: 
	cmp al, '+'
	je .saveOperator
	cmp al, '-'
	je .saveOperator
	cmp al, '*'
	je .saveOperator
	cmp al, '/'
	je .saveOperator

	inc rsi
	jmp .skipspace
	
.saveOperator:
	movzx rcx, al
	inc rsi
	ret
	
readOp: ;Jeno
	mov r10, 0
.skipSpace:
	movzx rax, byte[rsi]
	cmp al, ' '
	jne .readDigit
	inc rsi
	jmp .skipSpace
.readDigit:
	movzx rax, byte[rsi]
	cmp al, '0'
	jl .readDone
	cmp al, '9'
	jg .readDone

	sub al, '0'
	imul rbx, 10
	add rbx, rax
	
	inc r10	

	inc rsi
	cmp r10, 4
	jg error
	jmp .skipSpace
.readDone:
	ret
	

printString: ;Phoom
	push rbx
	push rdx
	mov rdx, 0
	mov rbx, rdi
.countString:
	cmp byte[rbx], NULL
	je .printOut
	inc rbx
	inc rdx
	jmp .countString

.printOut:
	cmp rdx, 0
	je .printDone

	mov rax, SYS_write
	mov rsi, rdi
	mov rdi, STDOUT
	syscall
	jmp .printDone

.printDone:
	pop rbx
	pop rdx
	ret
