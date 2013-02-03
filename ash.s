.text
	prompt: .ascii ">: "
	.equ SYS_WRITE, 1
	.equ SYS_EXIT, 60

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

_start:
	pushq %rbp
	movq %rsp, %rbp
	pushq 24(%rbp)
	call strlen
	movq %rax, %rdx
	movq 24(%rbp), %rsi
	movq $1, %rdi
	movq $SYS_WRITE, %rax
	syscall

_exit_without_error:
	movq $0, %rdi
	jmp _exit

_exit_with_error:
	movq $1, %rdi

_exit:
	movq $SYS_EXIT, %rax
	syscall
