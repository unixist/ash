.data
# Misc. strings
#  testStrchrChar: .ascii "a"
#  testStrchrString: .ascii "asdf\0"
  cmdUnknown: .ascii "Unknown command\n"
  cmdDelim: .ascii " "
	prompt: .ascii ">: "
	exitString: .ascii "exit"

# String identifiers for supported built-in commands
	cmdCd: .ascii "cd\0"
	cmdHelp: .ascii "help\0"

# Numeric identifiers for supported built-in commands
	.equ cmdCdNum, 0
	.equ cmdHelpNum, 1

# Command string lengths (e.g. "cd" is 2)
	.equ cmdCdStringLength, 2
	.equ cmdHelpStringLength, 4

# Misc. string lengths
	.equ promptLength, 3
  .equ cmdUnknownStringLength, 16
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
*	@param[in] String
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
	mov 24(%rbp), %r12 # Length of command entered

  cmp $cmdCdStringLength, %r12 
  jne _getCmd_tryHelpCmd
# Test to see whether the entered command is "cd"
	push %r12
	push %r11
	push $cmdCd
	call memcmp
  add $8, %rsp
  push $cmdCdNum
	cmp $0, %rax
	je _getCmd_success


# Test to see whether the entered command is "help"
  _getCmd_tryHelpCmd:
  cmp $cmdHelpStringLength, %r12
  jne _getCmd_tryNextCmd
  push $cmdHelp
  call memcmp
  cmp $0, %rax
  je _getCmd_success

# Test to see whether the entered command is "..."
# ...
  _getCmd_tryNextCmd:

# Command tests completed. Assume failure unless we jumped to success
  jmp _getCmd_failure

	_getCmd_success:
    pop %rax
		jmp _getCmd_exit

	_getCmd_failure:
		mov $-1, %rax

	_getCmd_exit:
# Clear the first two args to memcmp (command and length) 
    add $16, %rsp

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

# Stash the entered command length including any arguments
  push %rax

# See whether the program should quit (currently only if "exit" is entered)
	push %rax
	push $readBuffer
	call shouldQuit
  add $16, %rsp
  cmp $1, %rax
  je _loopPrompt_exit

# Look for a command delimiter to see whether a command was entered alone or with arguments
  push $cmdDelim
  push $readBuffer
  call strchr
  add $16, %rsp
# If we find a command delimiter, stash just the size of the command without arguments
  pop %r11
  cmp $-1, %rax
  cmovne %rax, %r11

  push %r11
  push $readBuffer
# Determine the command. Buffer and length are still the next arg on the stack
	call getCmd
	add $16, %rsp

	cmp $-1, %rax
# If the command is unrecognized or unexecutable
	je _loopPrompt_badCmd

	cmpq $1, %rax
	jne _loopPrompt

  _loopPrompt_badCmd:
    push $cmdUnknownStringLength
    push $cmdUnknown
    call write
    add $8, %rsp
    jmp _loopPrompt
# Not yet implemented

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
  push %rdx
  push %rsi
  push %rdi
	mov $promptLength, %rdx
	mov $prompt, %rsi
	mov $stdout, %rdi
	mov $sys_write, %rax
	syscall
  pop %rdi
  pop %rsi
  pop %rdx
	leave
	ret

write:
	push %rbp
	mov %rsp, %rbp
  push %rdx
  push %rsi
  push %rdi
	mov 16(%rbp), %rsi
	mov 24(%rbp), %rdx
	mov $stdout, %rdi
	mov $sys_write, %rax
	syscall
  pop %rdi
  pop %rsi
  pop %rdx
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
