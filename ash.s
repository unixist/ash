.data
	prompt: .ascii ">: "
	exitString: .ascii "exit\0"
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
	.equ SYS_FORK, 57
	.equ SYS_EXIT, 60
	.equ SYS_WAIT4, 61

.text
	.globl _start

strlen:
	push %rbp
	mov %rsp, %rbp
	mov 16(%rbp), %rdi
	xor %rax, %rax
	xor %rcx, %rcx
	not %rcx
	cld
	repne scasb
	not %rcx
	dec %rcx
	mov %rcx, %rax
	leave
	ret

shouldQuit:
	push %rbp
	mov %rsp, %rbp
	mov 16(%rbp), %r10
	mov 24(%rbp), %r11

	mov $exitStringLength, %r12
	cmp %r11, %r12
	jne _shouldQuit_no

	push %r11
	push $exitString
	push %r10
	call memcmp
	add $24, %rsp
	cmp $0, %rax
	je _shouldQuit_yes
	
	_shouldQuit_no:
	mov $0, %rax
	jmp _shouldQuit_exit

	_shouldQuit_yes:
	mov $1, %rax

	_shouldQuit_exit:
	leave
	ret

zeroMem:
	push %rbp
	mov %rsp, %rbp
	mov 16(%rbp), %rdi
	mov 24(%rbp), %rcx
	mov $0, %rax
	cld
	rep stosw

	leave
	ret

loopPrompt:
	push %rbp
	mov %rsp, %rbp

	_loopPrompt:
	call writePrompt
	call readPrompt

	dec %rax							#Kind of a hack to assume the entered text read will end w/ newline
	mov $readBuffer, %r10
	movb $0, (%rax, %r10, 1)

	push %rax
	push $readBuffer
	call shouldQuit
	addq $16, %rsp

	cmpq $1, %rax
	jne _loopPrompt

	_endLoopPrompt:
	leave
	ret

readPrompt:
	push %rbp
	mov %rsp, %rbp

	push $readBufferLength
	push $readBuffer
	call zeroMem
	add $16, %rsp

	mov $readBufferLength-1, %rdx
	mov $readBuffer, %rsi
	mov $STDIN, %rdi
	mov $SYS_READ, %rax
	syscall
	leave
	ret

writePrompt:
	push %rbp
	mov %rsp, %rbp
	mov $promptLength, %rdx
	mov $prompt, %rsi
	mov $STDOUT, %rdi
	mov $SYS_WRITE, %rax
	syscall
	leave
	ret

write:
	push %rbp
	mov %rsp, %rbp
	mov 16(%rbp), %rsi
	mov 24(%rbp), %rdx
	mov $STDOUT, %rdi
	mov $SYS_WRITE, %rax
	syscall
	leave
	ret

#Not exactly like memcmp(3)
#Return values:
##0: string1 is equal to string2
##!0: string1 is inequal to string2
memcmp:
	push %rbp
	mov %rsp, %rbp
	mov 16(%rbp), %r13
	mov 24(%rbp), %r14
	mov 32(%rbp), %rcx
	mov %rcx, %r9
	mov %rcx, %r10
	xorq %r11, %r11

	cmp $0, %rcx 						#Sanity check: only work with lengths >0
	jle _memcmp_done

	_memcmp_loop:
	sub %rcx, %r10
	movb (%r10, %r13, 1), %r11b
	cmpb %r11b, (%r10, %r14, 1)
	jne _memcmp_done
	mov %r9, %r10						#Reset %r10 to original len in order to sub at the top of the loop 
	dec %rcx
	cmp $0, %rcx
	jne _memcmp_loop

	_memcmp_done:
	mov %rcx, %rax
	leave
	ret

_start:
	push %rbp
	mov %rsp, %rbp
	call loopPrompt

_exit_without_error:
	mov $0, %rdi
	jmp _exit

_exit_with_error:
	mov $1, %rdi

_exit:
	mov $SYS_EXIT, %rax
	syscall
