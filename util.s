/**
 * @fn strchr
 * @brief       Determine the index of a character in a string
 * @param[in]   String - null-terminated
 * @param[in]   Character - to find within the string
 * @retval      Zero-index of the character within the string; -1 otherwise
 */
strchr:
  push %rbp
  mov %rsp, %rbp
  mov 16(%rbp), %r10 # String
  mov 24(%rbp), %rdx # Character

  mov $-1, %rcx
  mov $-1, %rax
  xor %r12, %r12
  xor %r13, %r13
  movb (%rdx), %r11b # Snag the character

  _strchrLoop:
    inc %rcx
    movb (%rcx, %r10, 1), %r12b
    cmpb $0, %r12b # Exit if we've reached a NULL byte
    je _strchrLoop_exit
    cmpb %r11b, %r12b
    je _strchrLoop_success
    jmp _strchrLoop

  _strchrLoop_success:
    mov %rcx, %rax

  _strchrLoop_exit:

  leave
  ret

/**
 *	@fn memcmp
 * @brief       Bytewise-compare the memory at two addresses. Not exactly like memcmp(3).
 * @param[in]   Address1 - first byte-stream to compare
 * @param[in]   Address2 - second byte-stream to compare
 * @param[in]   Number of bytes to compare
 * @retval      0 if memory regions are equal up to specified # of bytes; 1 otherwise
 */
memcmp:
	push %rbp
	mov %rsp, %rbp
  push %r9
  push %r10
  push %r11
  push %r12
  push %r13
  push %r14
  push %rcx

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
  pop %rcx
  pop %r14
  pop %r13
  pop %r12
  pop %r11
  pop %r10
  pop %r9
	leave
	ret

