.data
str: .ascii "Hello world!\n"

.text
.globl _start

_start:
   pushq %rbp
   movq %rsp, %rbp
   movq $13, %rdx
   leaq str, %rcx
   movq $0, %rbx
   movq $4, %rax
   int $0x80

   xorq %rbx, %rbx
   movq $1, %rax
   int $0x80
