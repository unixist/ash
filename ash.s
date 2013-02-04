.data
	prompt: .ascii ">: "
	exitString: .ascii "exit"
	readBuffer: 
		.ascii ""
		.rept 256
		.byte 0
		.endr
	.equ promptLength, 3
	.equ exitStringLength, 4
	.equ readBufferLength, 256
	.equ STDIN, 0
	.equ STDOUT, 1
	.equ STDERR, 2
	.equ SYS_READ, 0
	.equ SYS_WRITE, 1
	.equ SYS_OPEN, 2
	.equ SYS_CLOSE, 3
	.equ SYS_STAT, 4
	.equ SYS_ACCESS, 21
	.equ SYS_ACCESS, 22
	.equ SYS_FORK, 57
	.equ SYS_EXIT, 60
	.equ SYS_WAIT4, 61

.text
	.globl _start

strlen:
	pushq %rbp
	movq %rsp, %rbp
	movq 16(%rbp), %rdi
	xorq %rax, %rax
	xorq %rcx, %rcx
	notq %rcx
	cld
	repne scasb
	notq %rcx
	decq %rcx
	movq %rcx, %rax
	leave
	ret

shouldQuit:
	pushq %rbp
	movq %rsp, %rbp
	movq 16(%rbp), %r10
	pushq $exitStringLength
	pushq $exitString
	pushq %r10
	call memcmp
	notq %rax
	addq $24, %rsp
	leave
	ret

loopPrompt:
	pushq %rbp
	movq %rsp, %rbp

	_loopPrompt:
	call writePrompt
	call readPrompt
	movq %rax, %r10
	dec %rax				#Kind of a hack to assume the line read will end w/ newline
	pushq $readBuffer
	call write
	addq $8, %rsp

	push $readBuffer
	call shouldQuit
	addq $8, %rsp
	cmpq $0, %rax
	jne _loopPrompt

	leave
	ret

readPrompt:
	pushq %rbp
	movq %rsp, %rbp
	movq $readBufferLength-1, %rdx
	movq $readBuffer, %rsi
	movq $STDIN, %rdi
	movq $SYS_READ, %rax
	syscall
	leave
	ret

writePrompt:
	pushq %rbp
	movq %rsp, %rbp
	mov $promptLength, %rdx
	leaq prompt, %rsi
	movq $STDOUT, %rdi
	movq $SYS_WRITE, %rax
	syscall
	leave
	ret

write:
	pushq %rbp
	movq %rsp, %rbp
	movq 16(%rbp), %rsi
	movq $STDOUT, %rdi
	movq $SYS_WRITE, %rax
	syscall
	leave
	ret

#Not exactly like memcmp(3)
#Return values:
##0: string1 is equal to string2
##!0: string1 is inequal to string2

memcmp:
	pushq %rbp
	movq %rsp, %rbp
	movq 16(%rbp), %r13				#string1
	movq 24(%rbp), %r14				#string2
	movq 32(%rbp), %rcx				#length to compare
	movq %rcx, %r9
	movq %rcx, %r10
	xorq %r11, %r11

	cmp $0, %rcx 						#Sanity check: only work with lengths >0
	jle _memcmp_inequal

	_memcmp_loop:
	sub %rcx, %r10
	movb (%r10, %r13, 1), %r11b
	cmpb %r11b, (%r10, %r14, 1)
	jne _memcmp_inequal
	movq %r9, %r10						#Reset %r10 to original length
	dec %rcx
	cmp $-1, %rcx
	jg _memcmp_loop

	_memcmp_equal:
	inc %rcx

	_memcmp_inequal:
	movq %rcx, %rax

	_memcmp_done:
	leave
	ret

_start:
	pushq %rbp
	movq %rsp, %rbp
	call loopPrompt

_exit_without_error:
	movq $0, %rdi
	jmp _exit

_exit_with_error:
	movq $1, %rdi

_exit:
	movq $SYS_EXIT, %rax
	syscall
