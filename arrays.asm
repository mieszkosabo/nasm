SYS_READ    equ 0
STD_IN      equ 0
STD_OUT     equ 1

global _start


section .bss
  r  resb  1


section .text



_start:
  mov rdx, 14
  mov [r], dl
  mov r11, [r]

  inc r11
  mov [r], r11
  mov rdx, [r]
  cmp rdx, 14
  je  error

exit:
  mov     eax, 60
  xor     edi, edi        ; kod powrotu 0
  syscall

error:                      ; wyjście spowodowane złymi danymi
    mov     eax, 60
    mov     edi, 1          ; kod powrotu 1
    syscall