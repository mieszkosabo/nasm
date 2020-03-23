global _start

section .data
    NEWLINE db  `\n`
    arr   TIMES 42 db  0


section .text

_start:
  mov rsi, arr
  mov r9, 2
  mov byte [rsi + r9], 2
  mov r8, [arr + r9]
  cmp r8, 2
  jnz error 


exit:
  mov     eax, 60
  xor     edi, edi        ; kod powrotu 0
  syscall

error:                      ; wyjście spowodowane złymi danymi
    mov     eax, 60
    mov     edi, 1          ; kod powrotu 1
    syscall