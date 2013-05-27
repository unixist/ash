chdir:
	push %rbp
	mov %rsp, %rbp
	mov 16(%rbp), %r10
	mov $sys_chdir, %rax
	syscall
	leave
	ret
