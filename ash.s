.data
	prompt: .ascii ">: "
	exitString: .ascii "exit"
	cmdCd: .ascii "cd"
	readBuffer: 
		.ascii ""
		.rept 256
		.byte 0
		.endr

	.equ promptLength, 3
	.equ exitStringLength, 4
	.equ cmdCdStringLength, 2
	.equ readBufferLength, 256
	.equ stdin, 0
	.equ stdout, 1
	.equ stderr, 2
	.equ sysRead, 0
	.equ sysWrite, 1
	.equ sys_open, 2
	.equ sys_close, 3
	.equ sys_stat, 4
	.equ sys_access, 21
	.equ sys_fork, 57
	.equ sysExit, 60
	.equ sys_wait4, 61

.text
	.globl _start

/**
*	@fn strlen
*	@brief Calculate a string's length in bytes
*	@param[in] String whose length is be calculated
*	@param[out] String length
*/
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

# Before command is compared with $exitString, first see if their lengths match
	mov $exitStringLength, %r12
	cmp %r11, %r12
	jne _shouldNotQuit

	push %r11
	push $exitString
	push %r10
	call memcmp
	add $24, %rsp
	cmp $0, %rax
	je _shouldQuit
	
	_shouldNotQuit:
	mov $0, %rax
	jmp _shouldQuit_exit

	_shouldQuit:
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

# Assume command ends with a newline. Ending with an EOF will act wierd.
	dec %rax							
	mov $readBuffer, %r10
	movb $0, (%rax, %r10, 1)

	push %rax
	push $readBuffer
	call shouldQuit
	addq $16, %rsp

	cmpq $1, %rax
	jne _loopPrompt

	_loopPrompt_exit:
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
	mov $stdin, %rdi
	mov $sysRead, %rax
	syscall
	leave
	ret

writePrompt:
	push %rbp
	mov %rsp, %rbp
	mov $promptLength, %rdx
	mov $prompt, %rsi
	mov $stdout, %rdi
	mov $sysWrite, %rax
	syscall
	leave
	ret

write:
	push %rbp
	mov %rsp, %rbp
	mov 16(%rbp), %rsi
	mov 24(%rbp), %rdx
	mov $stdout, %rdi
	mov $sysWrite, %rax
	syscall
	leave
	ret

/**
 *	@fn memcmp
 * @brief Bytewise-compare the memory at two addresses. Not exactly like memcmp(3).
 * @param[in] Address1
 * @param[in] Address2
 * @param[in] Number of bytes to compare
 * @retval 0 if memory regions are equal up to specified # of bytes; 1 otherwise
 */
memcmp:
	push %rbp
	mov %rsp, %rbp
	mov 16(%rbp), %r13
	mov 24(%rbp), %r14
	mov 32(%rbp), %rcx
	mov %rcx, %r9
	mov %rcx, %r10
	xorq %r11, %r11

# Sanity check: only work with lengths >0
	cmp $0, %rcx 						
	jle _memcmp_exit

	_memcmpLoop:
	sub %rcx, %r10
	movb (%r10, %r13, 1), %r11b
	cmpb %r11b, (%r10, %r14, 1)
	jne _memcmp_exit
# Reset %r10 to original len in order to sub at the top of the loop
	mov %r9, %r10						 
	dec %rcx
	cmp $0, %rcx
	jne _memcmpLoop

	_memcmp_exit:
	mov %rcx, %rax
	leave
	ret

_start:
	push %rbp
	mov %rsp, %rbp
	call loopPrompt

_exitWithoutError:
	mov $0, %rdi
	jmp _exit

_exitWithError:
	mov $1, %rdi

_exit:
	mov $sysExit, %rax
	syscall
