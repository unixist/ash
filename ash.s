.data
# Misc. strings
	prompt: .ascii ">: "
	exitString: .ascii "exit"

# String identifiers for supported built-in commands
	cmdCd: .ascii "cd\0"

# Numeric identifiers for supported built-in commands
	.equ cmdCdNum, 0

# Command string lengths (e.g. "cd" is 2)
	.equ cmdCdStringLength, 2

# Misc. string lengths
	.equ promptLength, 3
	.equ exitStringLength, 4
	.equ readBufferLength, 256
	.equ pathBufferLength, 4096

# Process constants
	.equ stdin, 0
	.equ stdout, 1
	.equ stderr, 2

# Kernel system call constants
	.equ sys_read, 0
	.equ sys_write, 1
	.equ sys_open, 2
	.equ sys_close, 3
	.equ sys_stat, 4
	.equ sys_getcwd, 17
	.equ sys_access, 21
	.equ sys_chdir, 49
	.equ sys_fork, 57
	.equ sys_exit, 60
	.equ sys_wait4, 61

# Misc. buffers
	readBuffer: 
		.ascii ""
		.rept readBufferLength
		.byte 0
		.endr
	pathBuffer: 
		.ascii ""
		.rept pathBufferLength
		.byte 0
		.endr

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
	cmp $0, %rax
	je _shouldQuit
	
	_shouldNotQuit:
	mov $0, %rax
	jmp _shouldQuit_exit

	_shouldQuit:
	mov $1, %rax

	_shouldQuit_exit:
	add $24, %rsp
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

getCmd:
	push %rbp
	mov %rsp, %rbp
	xor %r10, %r10
	mov 16(%rbp), %r11 # Command entered

# Test to see whether the entered command is "cd"
	push $cmdCdStringLength
	push %r11
	push $cmdCd
	call memcmp
	add $16, %rsp

# I don't like moving the command number into %r10 before we know that it is, in fact
# the command that was entered, but it allows for an easy jmp to _success if so
	mov $cmdCdNum, %r10
	cmp $0, %rax
	je _getCmd_success

# More command tests
# ...
	

# Done with command tests

	_getCmd_success:
		mov %r10, %rax
		jmp _getCmd_exit

	_getCmd_failure:
		mov $-1, %rax

# Remove the passed-in command from the stack
	add $8, %rsp
	
	_getCmd_exit:

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
  cmp $1, %rax
  je _loopPrompt_exit

# Determine the command
# $readBuffer is still the next arg on the stack
	call getCmd

	cmp $-1, %rax
# If the command is unrecognized or unexecutable
	je _loopPrompt_badCmd

### Execute command here ###

	cmpq $1, %rax
	jne _loopPrompt

  _loopPrompt_badCmd:
# Not yet implemented

	_loopPrompt_exit:
	add $16, %rsp
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
	mov $sys_read, %rax
	syscall
	leave
	ret

getCwd:
	push %rbp
	mov %rsp, %rbp
	
	leave
	ret

writePrompt:
	push %rbp
	mov %rsp, %rbp
	mov $promptLength, %rdx
	mov $prompt, %rsi
	mov $stdout, %rdi
	mov $sys_write, %rax
	syscall
	leave
	ret

write:
	push %rbp
	mov %rsp, %rbp
	mov 16(%rbp), %rsi
	mov 24(%rbp), %rdx
	mov $stdout, %rdi
	mov $sys_write, %rax
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
	mov $sys_exit, %rax
	syscall
