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
